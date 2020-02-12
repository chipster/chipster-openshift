#!/bin/bash

# Build container images for running Chipster in K3s
#
# The necessary information is parsed from the OpenShift configurations.

set -e

if [ -z $1 ]; then
  echo "Usage bash build-image.bash {--all | --list | IMAGE_NAME}"
  exit 1
fi

all_images=$(ls ../templates/builds/ | grep -v chipster-jenkins | grep -v web-server-mylly)

if [ $1 = "--list" ]; then
    echo "$all_images"
    exit 0
fi

if [ $1 = "--all" ]; then
    images="$all_images"
else
    images="$1"
fi

while read -r build; do
    echo "** build $build"
    cmd="$(bash scripts/buildconfig-to-docker.bash ../templates/builds/$build)"
    #echo "build command: $cmd"
    bash -c "$cmd"
done <<< "$images"