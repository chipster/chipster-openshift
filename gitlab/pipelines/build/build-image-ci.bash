#!/bin/bash

# Build container images for running Chipster in K3s
#
# The necessary information is parsed from the OpenShift configurations.

set -e

if [ -z $3 ]; then
  echo "Usage bash build-image-ci.bash IMAGE_NAME TAG BRANCH"
  exit 1
fi

build="$1"
tag="$2"
branch="$3"

src_repo="image-registry.apps.2.rahti.csc.fi"
src_ns="chipster-images-dev"
dest_repo="image-registry.apps.2.rahti.csc.fi"
dest_ns="chipster-images-dev"


# transform unallowed characters
tag=$(echo $tag | tr ":" "-" | tr "+" "_")

echo "** make sure there is no old image with this tag"
sudo docker image rm $dest_repo/$dest_ns/$build:$tag || true

echo "** build $build"
# use branch as source image tag
# this allows us to skip build jobs easily, but will break if we are able run parallel build pipelines of same branch some day
cmd="$(bash ../../../k3s/scripts/buildconfig-to-docker.bash ../../../kustomize/builds/$build $src_repo/$src_ns/ $branch) -t $dest_repo/$dest_ns/$build:$tag"
#echo "build command: $cmd"
bash -c "$cmd"

echo "** push image"
bash push-image-ci.bash $dest_repo $dest_ns $build $tag $branch

echo "** delete local image"
sudo docker image rm $dest_repo/$dest_ns/$build:latest
sudo docker image rm $dest_repo/$dest_ns/$build:$tag

