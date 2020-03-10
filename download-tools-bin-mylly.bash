#!/bin/bash

set -e

source scripts/utils.bash

export PROJECT=$(oc project -q)

oc process -f templates/jobs/download-tools-bin-mylly.yaml --local \
	-p PROJECT=$PROJECT \
	| oc create -f - --validate
