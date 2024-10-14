#!/bin/bash

set -e

if [ -z $1 ]; then
  echo "Usage bash push-image-ci.bash IMAGE_NAME_AND_TAG"
  exit 1
fi

image="$1"

time sudo docker run \
    --privileged \
    --volume /var/run:/var/run \
    quay.io/skopeo/stable:latest \
        copy \
        --dest-creds $(cat $HOME/.docker/config.json | jq '."image-registry.apps.2.rahti.csc.fi".username' -r):$(cat $HOME/.docker/config.json | jq '."image-registry.apps.2.rahti.csc.fi".password' -r) \
        docker-daemon:image-registry.apps.2.rahti.csc.fi/chipster-images/$image \
        docker://image-registry.apps.2.rahti.csc.fi/chipster-images-dev/$image