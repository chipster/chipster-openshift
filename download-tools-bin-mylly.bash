#!/bin/bash

set -e

source scripts/utils.bash

view="{
      \"project\": \"$PROJECT\"
      }"

echo "$view" | mustache - templates/jobs/download-tools-bin-mylly.yaml | oc create -f - 
