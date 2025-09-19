#!/bin/bash

set -e

if [ -z $1 ]; then
  echo "Usage bash copy-from-docker-to-k3s.bash IMAGE"
  exit 1
fi

source_repo="image-registry.apps.2.rahti.csc.fi/chipster-images/"
source_image="$1"
source_tag="latest"
target_repo="$(cat ~/values.yaml | yq e -o json | jq -r '.image.chipsterImageRepo')"
target_image="$source_image"
target_tag="$(cat ~/values.yaml | yq e -o json | jq -r '.image.tag')"

echo "tag in Docker"

echo "   $source_repo$source_image:$source_tag"
echo "as $target_repo$target_image:$target_tag"

sudo docker tag $source_repo$source_image:$source_tag $target_repo$target_image:$target_tag

echo "copy from Docker to K3s"

sudo docker save $target_repo$target_image:$target_tag | sudo k3s ctr -n k8s.io images import -
  
# 2025-09-15: copied images are not visible in K3s
# time sudo docker run --privileged --volume /var/run:/var/run quay.io/skopeo/stable:latest copy \
#     docker-daemon:$source_repo$source_image:$source_tag \
#     containers-storage:$target_repo$target_image:$target_tag