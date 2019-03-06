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

bash run-job-with-tools-bin.bash "templates/jobs/download-tools-bin.bash" "$tools_bin_version"