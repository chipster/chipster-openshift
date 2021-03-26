#!/bin/bash

repo="$(cat helm/chipster/values.yaml | yq e '.image.chipsterImageRepo' -)"

for image in $(cat helm/chipster/values.yaml | yq e '.deployments[].image' - | sort | uniq); do
    sudo docker pull ${repo}${image}
done
