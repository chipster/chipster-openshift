#!/bin/bash

# parse the current project name
function get_project {
  oc project -q
}

# parse the current project domain (i.e. the address of this OpenShift)
function get_domain {
  #oc project | grep "Using project" | cut -d "\"" -f 4 | cut -d / -f 3 | cut -d : -f 1
  console=$(oc project | grep "Using project" | cut -d "\"" -f 4 | cut -d / -f 3 | cut -d : -f 1)

  if [[ $console == "rahti.csc.fi" ]]; then
    echo "rahtiapp.fi"
  elif [[ $console == "api.2.rahti.csc.fi" ]]; then
    echo "2.rahtiapp.fi"
  elif [[ $console == "api.okd.lumi-k.csc.fi" ]]; then
    echo "apps.okd.lumi-k.csc.fi"
  else
    >&2 echo "no app url defined for OpenShift console $console"
  fi
}

# Check if a DeploymentConfig exists. --ignore-not-found makes a missing DC a
# silent success with empty output, so other oc errors (e.g. an expired login)
# are still errors. Those exit the script, because the callers use these in an
# "if" or a "$(...)", where "set -e" doesn't apply and the status would be lost.
function dc_exists {
  local name
  name="$(oc get dc "$1" --ignore-not-found -o name)" || exit 1
  [ -n "$name" ]
}

# check if a DeploymentConfig exists and is scaled to 1 replica, i.e. an
# optional component is enabled in this project. A predicate like dc_exists and
# not a function that prints the replicas, because "exit" in a "$(...)" would
# only end the subshell and the script would go on after an oc error.
function dc_enabled {
  local replicas
  replicas="$(oc get dc "$1" --ignore-not-found -o jsonpath='{.spec.replicas}')" || exit 1
  [ "$replicas" == 1 ]
}

function wait_dc {
  local replicas
  service="$1"
  is_printed="false"
  # fail with a message that names the project, instead of oc's own NotFound
  # error from the loop below
  if ! dc_exists "$service"; then
    >&2 echo "ERROR: DeploymentConfig $service not found in project $(oc project -q)"
    return 1
  fi
  # stop if oc fails while polling (e.g. the login expires) instead of looping
  # forever: an unquoted test used to end the loop with a syntax error, a quoted
  # one would compare the empty output and never end
  while true; do
    replicas="$(oc get dc "$service" -o jsonpath='{.status.availableReplicas}')" || return 1
    [ "$replicas" == 1 ] && break
    if [ "$is_printed" == "false" ]; then
      echo "waiting $service to start"
      is_printed="true"
    else
      echo -n "."
    fi
    sleep 2
  done
  echo ""
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
    value="$(cat $deploy_config_path_project | yq e ."$key")"
    # if the key was found    
    if [ "$value" != "null" ]; then
      echo "$value"
      return
    fi
  fi
  
  # not found from project specific, try shared
  if [ -f $deploy_config_path_shared ]; then
    value="$(cat $deploy_config_path_shared | yq e ."$key")"
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
    echo "image_project is not configured, assuming all images are found from the current project"
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

function make_temp {
  name="$1"

  if mktemp --version > /dev/null 2>&1; then
    # GNU
    mktemp -d -t $name.XXX
  else
    # MacOS
    mktemp -d -t $name
  fi
}