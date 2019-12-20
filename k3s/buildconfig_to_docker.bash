#!/bin/bash

set -e
set -x

dir="$1"

if [[ -z $dir ]]; then
  echo "Usage: $(basename $0) DOCKERFILE_AND_BUILDCONFIG_DIR"
  exit 1
fi

cmd="cat $dir/Dockerfile"

uri=$(cat $dir/*.yaml | yq r - objects[0].spec.source.git.uri)

image_count=$(cat $dir/*.yaml | yq r - objects[0].spec.source.images --tojson | jq '. | length')

if [[ $image_count != 0 ]]; then 
    last_index=$(($image_count - 1))
    for i in $(seq 0 $last_index); do
        image=$(cat $dir/*.yaml | yq r - objects[0].spec.source.images[$i].from.name)
        destination=$(cat $dir/*.yaml | yq r - objects[0].spec.source.images[$i].paths[0].destinationDir)
        source=$(cat $dir/*.yaml | yq r - objects[0].spec.source.images[$i].paths[0].sourcePath)
        dir=$(basename $destination)

        if [[ $source == *"mylly"* ]]; then
            echo "skip mylly"
        else
            cmd="$cmd | sed \"s#COPY $dir#COPY --from=$image $source#\""
        fi
    done
fi

cmd="$cmd | tee /dev/tty"

if [[ $uri == "null" ]]; then
    cmd="$cmd | sudo docker build -t $build -"
else
    cmd="$cmd | sudo docker build -t $build -f - $uri"
fi

echo $cmd