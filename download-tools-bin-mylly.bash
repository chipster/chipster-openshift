#!/bin/bash

set -e

source script-utils/deploy-utils.bash

view="{
      \"project\": \"$PROJECT\"
      }"

echo "$view" | mustache - templates/jobs/download-tools-bin-mylly.yaml | oc create -f - 
