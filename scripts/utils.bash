#!/bin/bash

# parse the current project name
function get_project {
  oc project -q
}

# parse the current project domain (i.e. the address of this OpenShift)
function get_domain {
  #oc status | grep "In project" | cut -d " " -f 6 | cut -d / -f 3 | cut -d : -f 1
  console=$(oc status | grep "In project" | cut -d / -f 3 | cut -d : -f 1)

  if [[ $console == "rahti.csc.fi" ]]; then
    echo "rahtiapp.fi"
  elif [[ $console == "rahti-int.csc.fi" ]]; then
    echo "rahti-int-app.csc.fi"
  else
    >&2 echo "no app url defined for OpenShift console " + $console
  fi
}

# retry the command for max five times or until it's exit value is zero 
function retry {
  for i in {1..5}; do
    $@ && break
    sleep 1
  done	
}

function generate_password {
	openssl rand -base64 15
}

function get_db_password {
  secret="$1"
  role="$2"
  get_password $secret "$role-db-password"
}

function get_password {
  secret="$1"
  key="$2"
  oc get secret $secret -o json | jq -r .data[\"$key\"] | base64 --decode
}

# Find the object in the given file with given type (i.e. "kind") and name. 
# Apply the given yq script to it.
function patch_kind_and_name {

  file="$1"
  kind="$2"
  name="$3"
  script="$4"
  verbose="$5"
  
  if [ ! -f "$file" ]; then
    echo "patch failed, file not found: $file"
    exit 1
  fi
  
  found="false"

  # check the number of objects in the file and iterate those
  for i in $(seq 0 $(yq r $file --tojson | jq '.items | length')); do
  
  	# check if type and name match
    kind_of_i=$(yq r $file items[$i].kind)
    name_of_i=$(yq r $file items[$i].metadata.name)
    if [ "$kind" = "$kind_of_i" ]; then
      if [ "$name" = "$name_of_i" ]; then
        if [ "$verbose" = true ]; then
          echo $kind $name:
        fi
        patch_index $file "$script" $verbose
        found="true"
  	  fi  
  	fi
  done
  
  if [ "$found" = "false" ]; then
    echo "patch failed, object not found: $kind $name from $file"
    exit 1
  fi
}

# Find the objects in the given file with given type (i.e. "kind"). 
# Apply the given yq script to them.
function patch_kind {

  file="$1"
  kind="$2"
  script="$3"
  
  if [ ! -f "$file" ]; then
    echo "patch failed, file not found: $file"
    exit 1
  fi
  
  found="false"

  # check the number of objects in the file and iterate those
  for i in $(seq 0 $(yq r $file --tojson | jq '.items | length')); do
  
  	# check if type and name match
    kind_of_i=$(yq r $file items[$i].kind)
    #name_of_i=$(yq r $file items[$i].metadata.name)
    if [ "$kind" = "$kind_of_i" ]; then
	    #echo $kind $name_of_i:
	    patch_index $file "$script" false
	    found="true"
  	fi
  done
  
  if [ "$found" = "false" ]; then
    echo "patch failed, object not found: $kind from $file"
    exit 1
  fi
}

function patch_index {
	file="$1"
	script="$2"
	verbose="$3"
	
	# prepend all script keys with the found path
	# insert $script from the end instead of pipe to avoid
	# creating a subshell, where we couldn't update $script2
	script2=""
	while read line; do
	  # skip empty or whitespace lines 
	  if [[ -n "${line// }" ]]; then
	  
	    if [ "$verbose" = true ]; then
	      echo "  set $line"
	    fi
	      
	    script2+="items[$i].$line"
	    script2+=$'\n'
	  fi
	done < <(echo "$script")
	
	# apply the script to the file
	echo "$script2" | yq w -i $file items[$i] --script -
}

function delete_all {

  kind="$1"

  oc delete $kind --all

  is_printed="false"
  while [ $(oc get $kind -o json | jq '.items | length') != 0 ]; do
    if [ $is_printed == "false" ]; then
      echo "waiting all ${kind}s to get deleted"
      is_printed="true"
    else
      echo -n "."
    fi 
    sleep 2
  done
  echo ""
}

function wait_dc {
  service="$1"
  is_printed="false"
  while [ $(oc get dc $service -o json | jq .status.availableReplicas) != 1 ]; do
    if [ $is_printed == "false" ]; then
      echo "waiting $service to start"
      is_printed="true"
    else
      echo -n "."
    fi 
    sleep 2
  done
  echo ""
}

function get_secret {
  secret_name="$1"
  subproject="$2"
  
  if [ -z $subproject ]; then
    app="chipster"
  else
    app="chipster-$subproject"
  fi
  
  secret_template='{
    "kind": "List",
    "apiVersion": "v1",
    "metadata": {},
    "items": [
        {
            "kind": "Secret",
            "apiVersion": "v1",
            "metadata": {
                "name": "'$secret_name'",
                "labels": {
		    		"subproject": "'$subproject'",
		    		"app": "'$app'"
		    	}
            },
            "data": {
            },
            "type": "Opaque"
        }
    ]
}'

  echo "$secret_template"
}

function add_literal_to_secret {
  secret_file=$1
  key="$2"
  value="$3"
 
  tmp_file=${secret_file}_add_to_secret_temp
  encoded_value="$(echo "$value" | base64)"
  
  cat $secret_file \
  | jq ".items[0].data.\"$key\"=\"$encoded_value\"" \
  > $tmp_file
  
  mv $tmp_file $secret_file
}

function add_file_to_secret {
  secret_file=$1
  key="$2"
  file="$3"
  
  add_literal_to_secret "$secret_file" "$key" "$(cat "$file")"
}

function psql {
  service="$1"
  db="$2"
  sql="$3"
  
  wait_dc "$service"
  
  oc rsh dc/$service bash -c "psql -c \"$sql\""
}

function get_deploy_config {

  private_config_path="$1"
  key="$2"
  PROJECT="$3"
  DOMAIN="$4"

  deploy_config_path_shared="$private_config_path/chipster-all/deploy.yaml"
  deploy_config_path_project="$private_config_path/$PROJECT.$DOMAIN/deploy.yaml"

  # if project specific file exists
  if [ -f $deploy_config_path_project ]; then
    value="$(yq r $deploy_config_path_project "$key")"
    # if the key was found    
    if [ "$value" != "null" ]; then
      echo "$value"
      return
    fi
  fi
  
  # not found from project specific, try shared
  if [ -f $deploy_config_path_shared ]; then
    value="$(yq r $deploy_config_path_shared "$key")"
    if [ "$value" != "null" ]; then
      echo "$value"
      return
    fi
  fi
}

function wait_job {
  job="$1"
  phase="$2"
  
  
  
  is_printed="false"
  while true; do
    pod="$(oc get pod  | grep $job | grep $phase | cut -d " " -f 1)"
    if [ -n "$pod" ]; then
      break
    fi
    
    if [ $is_printed == "false" ]; then
      echo "waiting $job to be in phase $phase"
      is_printed="true"
    else
      echo -n "."
    fi    
    sleep 2
  done
  echo ""
}

function get_image_project {
      
  private_config_path="$1"
  PROJECT="$2"
  DOMAIN="$3"
  
  image_project=$(get_deploy_config $private_config_path image-project $PROJECT $DOMAIN)
  
  if [ -z "$image_project" ]; then
    echo "image_project is not configure, assuming all images are found from the current project"
    image_project="$(oc project -q)"
  fi
  
  echo "$image_project"
}

function follow_job {

  job="$1"
  
  wait_job $job Running

  pod="$(oc get pod  | grep $job | grep "Running" | cut -d " " -f 1)"
  oc logs --follow $pod
}
