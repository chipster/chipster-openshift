#!/bin/bash

# Build container images for running Chipster in K3s
#
# The necessary information is parsed from the OpenShift configurations.

set -e

if [ -z $2 ]; then
  echo "Usage bash build-image-ci.bash IMAGE_NAME TAG"
  exit 1
fi

build="$1"
tag="$2"

# transform unallowed characters
tag=$(echo $tag | tr ":" "-" | tr "+" "_")

echo "** build $build"
cmd="$(bash ../k3s/scripts/buildconfig-to-docker.bash ../kustomize/builds/$build) -t image-registry.apps.2.rahti.csc.fi/chipster-images/$build:$tag"
#echo "build command: $cmd"
bash -c "$cmd"
