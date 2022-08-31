#!/bin/bash

set -e

command -v yq >/dev/null 2>&1 || { echo >&2 "I require yq but it's not installed.  Aborting."; exit 1; }

source scripts/utils.bash

tools_bin_version="$1"
tools_bin_size="$2"

if [ -z $tools_bin_version ]; then
  echo "Usage:   bash download-tools-bin.bash TOOLS_BIN_VERSION TOOLS_BIN_SIZE"
  echo "Example: bash download-tools-bin.bash chipster-3.15.6 550Gi"
  echo ""
  echo "Create an OpenShift job for downloading the specified tools-bin version from the object storage and follow its output."
  echo ""
  exit 1
fi


pvc_name="tools-bin-$tools_bin_version"

if oc get pvc $pvc_name; then
  echo "$pvc_name exists already"
  exit 1
fi

oc process -f templates/jobs/pvc.yaml --local \
	-p NAME=$pvc_name \
	-p SIZE=$tools_bin_size \
  -p STORAGE_CLASS="glusterfs-storage" \
	| oc create -f - --validate
	
temp_pvc="${pvc_name}-temp"
while oc get pvc $temp_pvc; do
  oc delete pvc $temp_pvc
  sleep 1
done

oc process -f templates/jobs/pvc.yaml --local \
	-p NAME=$temp_pvc \
	-p SIZE=400Gi \
  -p STORAGE_CLASS="standard-rwo" \
	| oc create -f - --validate

bash run-job-with-tools-bin.bash "templates/jobs/download-tools-bin.bash" "$tools_bin_version" "$temp_pvc"

#TODO how to run this after the job has finished?
#oc delete pvc $temp_pvc
