# Find the objects in the given file with given type (i.e. "kind") and name. 
# Apply the given yq script to it.
function patch_kind_and_name {

  file="$1"
  kind="$2"
  name="$3"
  script="$4"

  # check the number of objects in the file and iterate those
  for i in $(seq 0 $(yq r $file --tojson | jq '.items | length')); do
  
  	# check if type and name match
    kind_of_i=$(yq r $file items[$i].kind)
    name_of_i=$(yq r $file items[$i].metadata.name)
    if [ "$kind" = "$kind_of_i" ]; then
      if [ "$name" = "$name_of_i" ]; then
        
        echo $kind $name:
        
        # prepend all script keys with the found path
        # insert $script from the end instead of pipe to avoid
        # creating a subshell, where we couldn't update $script2
        while read line; do
          # skip empty or whitespace lines 
          if [[ -n "${line// }" ]]; then
          
            echo "  set $line"  
            script2+="items[$i].$line"
            script2+=$'\n'
          fi
        done < <(echo "$script")
        
        # apply the script to the file
  	    echo "$script2" | yq w -i $file items[$i] --script -
  	  fi  
  	fi
  done
}

# parse the current project domain (i.e. the address of this OpenShift)
function get_domain {
  console=$(oc status | grep "In project" | cut -d / -f 3 | cut -d : -f 1)

  if [[ $console == "rahti.csc.fi" ]]; then
    echo "rahtiapp.fi"
  elif [[ $console == "rahti-int.csc.fi" ]]; then
    echo "rahti-int-app.csc.fi"
  else
    >&2 echo "no app url defined for OpenShift console " + $console
  fi
}