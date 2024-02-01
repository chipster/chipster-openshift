#!/bin/bash

set -e

if [ -f ~/values.yaml ]; then
    repo="$(cat ~/values.yaml | yq e '.image.chipsterImageRepo' -)"
    tag="$(cat ~/values.yaml | yq e '.image.tag' -)"
fi

if [ "$repo" == "null" ]; then
    
    repo="$(cat helm/chipster/values.yaml | yq e '.image.chipsterImageRepo' -)"
    echo "default image repository: $repo"
else
    echo "image repository configured in ~/values.yaml: $repo"
fi

if [ "$tag" == "null" ]; then
    
    tag="$(cat helm/chipster/values.yaml | yq e '.image.tag' -)"
    echo "default image tag: $tag"
else
    echo "image tag configured in ~/values.yaml: $tag"
fi


for build in ../kustomize/builds/*/; do 
    image="$(basename $build)"
    echo "** pull ${repo}$image:$tag"
    sudo k3s crictl pull ${repo}$image:$tag
done
