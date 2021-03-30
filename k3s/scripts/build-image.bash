#!/bin/bash

# Build container images for running Chipster in K3s
#
# The necessary information is parsed from the OpenShift configurations.

set -e

if [ -z $1 ]; then
  echo "Usage bash build-image.bash {--all | --list | IMAGE_NAME}"
  exit 1
fi

# ls -d lists only directories
# xargs removes paths
# sort to order short words before long, i.e. "base" before "base-java", like plain ls used to do it
all_images="$(ls -d ../kustomize/builds/*/ | xargs -n 1 basename | sort)"

if [ $1 = "--list" ]; then
    echo "$all_images"
    exit 0
fi

if [ $1 = "--all" ]; then
    images="$all_images"
else
    images="$1"
fi

# this assumes that source images are built before images that depend on them in alphabetical order (provided by ls)
while read -r build; do
    echo "** build $build"
    cmd="$(bash scripts/buildconfig-to-docker.bash ../kustomize/builds/$build)"
    #echo "build command: $cmd"
    bash -c "$cmd"
done <<< "$images"