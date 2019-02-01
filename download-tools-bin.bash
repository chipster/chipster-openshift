#!/bin/bash

set -e

source scripts/utils.bash

view="{
      \"project\": \"$PROJECT\"
      }"

echo "$view" | mustache - templates/jobs/download-tools-bin.yaml | oc create -f - 
