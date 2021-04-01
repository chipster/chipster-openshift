#!/bin/bash

repo="$(cat helm/chipster/values.yaml | yq e '.image.chipsterImageRepo' -)"

# images needed for running
# for image in $(cat helm/chipster/values.yaml | yq e '.deployments[].image' - | sort | uniq); do
#     sudo docker pull ${repo}${image}
# done

# all images needed for builds
for build in ../kustomize/builds/*/; do 
    image="$(basename $build)"
    sudo docker pull ${repo}$image
    sudo docker image tag ${repo}$image $image
done
