#!/bin/bash

set -e

source scripts/utils.bash

export PROJECT=$(oc project -q)
export DOMAIN=$(get_domain)

view="{
      \"project\": \"$PROJECT\"
      }"

echo "$view" | mustache - templates/jobs/download-tools-bin-mylly.yaml | oc create -f - 
