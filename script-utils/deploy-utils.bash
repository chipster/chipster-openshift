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

export PROJECT=$(get_project)
export DOMAIN=$(get_domain)
