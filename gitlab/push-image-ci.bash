#!/bin/bash

set -e

if [ -z $4 ]; then
  echo "Usage bash push-image-ci.bash IMAGE_REPOSITORY IMAGE_NAMESPACE IMAGE TAG"
  exit 1
fi

image_repository="$1"
image_namespace="$2"
image="$3"
tag="$4"

username="$(cat $HOME/.docker/config.json | jq '."'$image_repository'".username' -r)"
password="$(cat $HOME/.docker/config.json | jq '."'$image_repository'".password' -r)"

time sudo docker run \
    --privileged \
    --volume /var/run:/var/run \
    quay.io/skopeo/stable:latest \
        copy \
        --dest-creds $username:$password \
        docker-daemon:$image_repository/$image_namespace/$image:$tag \
        docker://$image_repository/$image_namespace/$image:$tag

# delete local image
time sudo docker run \
    --privileged \
    --volume /var/run:/var/run \
    quay.io/skopeo/stable:latest \
        delete \
        docker-daemon:$image_repository/$image_namespace/$image:$tag