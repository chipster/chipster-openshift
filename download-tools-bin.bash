#!/bin/bash

set -e

source scripts/utils.bash

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

tools_bin_version="$1"

if [ -z $tools_bin_version ]; then
  echo "Usage: bash download-tools-bin.bash TOOLS_BIN_VERSION"
  exit 1
fi

PROJECT=$(oc project -q)
      
private_config_path="../chipster-private/confs"
image_project=$(get_deploy_config $private_config_path image_project)
if [ -z "$image_project" ]; then
  echo "image_project is not configure, assuming all images are found from the current project"
  image_project=$PROJECT
fi

if oc get job download-tools-bin > /dev/null 2>&1; then
  oc delete job download-tools-bin
fi

oc process -f templates/jobs/download-tools-bin.yaml --local \
	-p IMAGE_PROJECT=$image_project \
	-p TOOLS_BIN_VERSION=$tools_bin_version \
	| oc create -f - 
	
wait_job download-tools-bin Running

pod="$(oc get pod  | grep download-tools-bin | grep "Running" | cut -d " " -f 1)"
oc logs --follow $pod
