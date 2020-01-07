#!/bin/bash

set -e
#set -x

dir="$1"

if [[ -z $dir ]]; then
  echo "Usage: $(basename $0) DOCKERFILE_AND_BUILDCONFIG_DIR"
  exit 1
fi

build="$(basename $dir)"

cmd="cat $dir/Dockerfile"

uri=$(cat $dir/*.yaml | yq r - objects[0].spec.source.git.uri)

image_count=$(cat $dir/*.yaml | yq r - objects[0].spec.source.images --tojson | jq '. | length')

if [[ $image_count != 0 ]]; then 
    last_index=$(($image_count - 1))
    for i in $(seq 0 $last_index); do
        image=$(cat $dir/*.yaml | yq r - objects[0].spec.source.images[$i].from.name)
        destination=$(cat $dir/*.yaml | yq r - objects[0].spec.source.images[$i].paths[0].destinationDir)
        source=$(cat $dir/*.yaml | yq r - objects[0].spec.source.images[$i].paths[0].sourcePath)
        source_basename=$(basename $source)
        copy_line="$(cat $dir/Dockerfile | grep "COPY $destination")"
        copy_destination="$(echo "$copy_line" | cut -d " " -f 3)"
        docker_copy_line="COPY --from=$image $source $copy_destination/$source_basename"

        # >&2 echo "copy from image:                      $image"
        # >&2 echo "path:                                 $source"
        # >&2 echo "to build context path:                $destination"
        # >&2 echo "original COPY line in Dockerfile:     $copy_line"
        # >&2 echo "copy destination:                     $copy_destination"
        # >&2 echo "dockerized COPY line:                 $docker_copy_line"
        

        if [[ $source == *"mylly"* ]]; then
            >&2 echo "skip mylly"
            cmd="$cmd | sed \"s#$copy_line##\""
        else
            cmd="$cmd | sed \"s#$copy_line#$docker_copy_line#\""
        fi
    done

    >&2 echo "modified Dockerfile:"
    >&2 echo "$(bash -c "$cmd")"
fi

cmd="$cmd | tee /dev/tty"

if [[ $uri == "null" ]]; then
    cmd="$cmd | sudo docker build -t $build -"
else
    cmd="$cmd | sudo docker build -t $build -f - $uri"
fi

echo $cmd