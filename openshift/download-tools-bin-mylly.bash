#!/bin/bash

set -e

source ../scripts/utils.bash

PROJECT=$(oc project -q)

if oc get job download-tools-bin-mylly > /dev/null 2>&1; then
  oc delete job download-tools-bin-mylly
fi

oc process -f jobs/download-tools-bin-mylly.yaml --local \
	-p PROJECT=$PROJECT \
	| oc create -f - --validate
