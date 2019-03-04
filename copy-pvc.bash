#!/bin/bash

set -e

source scripts/utils.bash

source_pvc="$1"
destination_pvc="$2"

if [ -z $destination_pvc ]; then
  echo "Usage: bash copy-pvc.bash SOURCE_PVC DESTINATION_PVC"
  exit 1
fi

PROJECT=$(oc project -q)
DOMAIN=$(get_domain)
      
private_config_path="../chipster-private/confs"
image_project=$(get_image_project $private_config_path $PROJECT $DOMAIN)

if oc get job copy-pvc > /dev/null 2>&1; then
  oc delete job copy-pvc
fi

oc process -f templates/jobs/copy-pvc.yaml --local \
	-p IMAGE_PROJECT=$image_project \
	-p SOURCE_PVC=$source_pvc \
	-p DESTINATION_PVC=$destination_pvc \
	| oc create -f - 
	
follow_job copy-pvc