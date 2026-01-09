#!/bin/bash

# Build container images for running Chipster in K3s
#
# The necessary information is parsed from the OpenShift configurations.

set -e

if [ -z $1 ]; then
  echo "Usage bash build-image.bash IMAGE_NAME"
  exit 1
fi

build="$1"

conf_tag="$(cat ~/values.yaml | yq -o=json | jq '.image.tag' -r)"
conf_repo="$(cat ./helm/chipster/values.yaml | yq -o=json | jq '.image.chipsterImageRepo' -r)"

read -p "Image tag [$conf_tag]: " user_tag

if [ -z "$user_tag" ]; then
    image_tag="$conf_tag"
else
    image_tag="$user_tag"
fi

read -p "Image repository [$conf_repo]: " user_repo

if [ -z "$user_repo" ]; then
    image_repo="$conf_repo"
else
    image_repo="$user_repo"
fi


echo "image tag: $image_tag"
echo "image repository $image_repo"

echo "** build $build"
# using the same tag as source tag and destination tag is handy, when we want to build and test images in a development VM
echo bash scripts/buildconfig-to-buildah.bash ../kustomize/builds/$build $image_repo $image_tag $image_tag
cmd="$(bash scripts/buildconfig-to-buildah.bash ../kustomize/builds/$build $image_repo $image_tag $image_tag)"
#echo "build command: $cmd"
bash -c "$cmd"

echo "copy image from podman to k3s"
podman save $image_repo$build:$image_tag | pv | sudo k3s ctr -n k8s.io images import -