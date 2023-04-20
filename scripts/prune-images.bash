#!/bin/bash

set -e

imagestream="$1"

if [ -z $imagestream ]; then
  echo "Usage:   bash prune-images.bash IMAGESTREAM"
  echo ""
  echo "Example 1: bash prune-images.bash toolbox"
  echo 'Example 2: for is in $(oc get is -o name | cut -d "/" -f 2); do echo $is; bash scripts/prune-images.bash $is; done'
  echo ""
  echo "Remove old images from the imagestream history of the tag "latest". The current image is kept."
  echo ""
  exit 1
fi

if [ $(oc get is $imagestream -o json | jq '.status.tags[0].tag' -r) != "latest" ]; then
    echo "The first tag is not 'latest'."
    exit
fi

echo "found $(oc get is $imagestream -o json | jq '.status.tags[0].items | length' -r) image(s)"

username=$(oc config view -o json | jq '."current-context"' -r | cut -d "/" -f 3)
domain=$(oc config view -o json | jq '."current-context"' -r | cut -d "/" -f 2)
namespace=$(oc config view -o json | jq '."current-context"' -r | cut -d "/" -f 1)
token=$(oc config view -o json --raw | jq '.users[] | select(.name | contains("'$domain'")) | .user.token' -r)

skopeo login -u $username -p $token docker-registry.rahti.csc.fi

# use "skopeo" instead of "oc tag" because "oc tag" doesn't work if the imagestream has a dot in its name
# oc tag $imagestream:latest $imagestream:latest-copy
skopeo copy docker://docker-registry.rahti.csc.fi/$namespace/$imagestream:latest docker://docker-registry.rahti.csc.fi/$namespace/$imagestream:latest-copy

oc tag -d $imagestream:latest

# oc tag $imagestream:latest-copy $imagestream:latest
skopeo copy docker://docker-registry.rahti.csc.fi/$namespace/$imagestream:latest-copy docker://docker-registry.rahti.csc.fi/$namespace/$imagestream:latest

oc tag -d $imagestream:latest-copy

echo "now $(oc get is $imagestream -o json | jq '.status.tags[0].items | length' -r) image"



