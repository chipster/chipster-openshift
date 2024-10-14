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
src_repo="image-registry.apps.2.rahti.csc.fi"
src_ns="chipster-images-dev"
dest_repo="image-registry.apps.2.rahti.csc.fi"
dest_ns="chipster-images-dev"

# transform unallowed characters
tag=$(echo $tag | tr ":" "-" | tr "+" "_")

echo "** build $build"
cmd="$(bash ../k3s/scripts/buildconfig-to-docker.bash ../kustomize/builds/$build $src_repo/$src_ns/) -t $dest_repo/$dest_ns/$build:$tag"
#echo "build command: $cmd"
bash -c "$cmd"

echo "** push image"
bash push-image-ci.bash $dest_repo $dest_ns $build $tag

echo "** delete local image"
sudo docker image rm $dest_repo/$dest_ns/$build:latest
sudo docker image rm $dest_repo/$dest_ns/$build:$tag

