#!/bin/bash

set -e

source scripts/utils.bash

tools_bin_version="$1"

if [ -z $tools_bin_version ]; then
  echo "Usage: bash download-tools-bin.bash TOOLS_BIN_VERSION"
  echo ""
  echo "Create an OpenShift job for downloading the specified tools-bin version from the object storage and follow its output."
  echo ""
  exit 1
fi

PROJECT=$(oc project -q)
DOMAIN=$(get_domain)
      
private_config_path="../chipster-private/confs"
image_project=$(get_image_project $private_config_path $PROJECT $DOMAIN)

if oc get job download-tools-bin > /dev/null 2>&1; then
  oc delete job download-tools-bin
fi

oc process -f templates/jobs/download-tools-bin.yaml --local \
	-p IMAGE_PROJECT=$image_project \
	-p TOOLS_BIN_VERSION=$tools_bin_version \
	| oc create -f - 
	
follow_job download-tools-bin