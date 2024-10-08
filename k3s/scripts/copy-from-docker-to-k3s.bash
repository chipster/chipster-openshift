#!/bin/bash

set -e

if [ -z $1 ]; then
  echo "Usage bash copy-from-docker-to-k3s.bash IMAGE"
  exit 1
fi

image="$1"

time sudo docker run --privileged --volume /var/run:/var/run quay.io/skopeo/stable:latest copy \
    docker-daemon:image-registry.apps.2.rahti.csc.fi/chipster-images/$image:latest \
    containers-storage:image-registry.apps.2.rahti.csc.fi/chipster-images/$image:latest