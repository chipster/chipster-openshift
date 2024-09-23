#!/bin/bash

# The information about build dependencies is in the BuildConfig objects 
# (supported in OpenShfit, another variant of Kubernetes), which don't work 
# in k3s. We have to dig out the GitHub urls and some paths from these objects 
# in bash. This is a small utility scripts that converts the BuildConfig and 
# Dockerfile to a `docker build` command. For example running
# 
#   $ bash k3s/buildconfig-to-docker.bash templates/builds/base
# 
# prints
#
#   cat ../templates/builds/base/Dockerfile | tee /dev/tty | sudo docker build -t base -
#
# This one was simple, but it gets a bit tortuous when the images copy 
# directories from other images:
#
#   $ bash k3s/buildconfig-to-docker.bash templates/builds/web-server
#
#   cat templates/builds/web-server/Dockerfile | sed "s#COPY chipster-web /opt/chipster#COPY --from=chipster-web:latest /home/user/chipster-web /opt/chipster/chipster-web#" | sed "s#COPY manual /opt/chipster/chipster-web/assets#COPY --from=chipster-tools:latest /home/user/chipster-tools/manual /opt/chipster/chipster-web/assets/manual#" | tee /dev/tty | sudo docker build -t web-server -
# 

set -e
#set -x

dir="$1"

if [[ -z $dir ]]; then
  echo "Usage: $(basename $0) DOCKERFILE_AND_BUILDCONFIG_DIR"
  exit 1
fi

build="$(basename $dir)"

image_repository="image-registry.apps.2.rahti.csc.fi/chipster-images/"

cmd="cat $dir/Dockerfile | sed \"s#FROM #FROM ${image_repository}#\""

uri=$(cat $dir/*.yaml | yq e .spec.source.git.uri -)
branch=$(cat $dir/*.yaml | yq e .spec.source.git.ref -)

image_count=$(cat $dir/*.yaml | yq e .spec.source.images - -o=json | jq '. | length')

if [[ $image_count != 0 ]]; then 
    last_index=$(($image_count - 1))
    for i in $(seq 0 $last_index); do
        image=$(cat $dir/*.yaml | yq e .spec.source.images[$i].from.name -)
        destination=$(cat $dir/*.yaml | yq e .spec.source.images[$i].paths[0].destinationDir -)
        source=$(cat $dir/*.yaml | yq e .spec.source.images[$i].paths[0].sourcePath -)
        source_basename=$(basename $source)
        if ! copy_line="$(cat $dir/Dockerfile | grep "COPY $destination")"; then 
            copy_line=$(cat $dir/Dockerfile | grep "COPY . ")
        fi
        copy_destination="$(echo "$copy_line" | cut -d " " -f 3)"
        docker_copy_line="COPY --from=$image_repository$image $source $copy_destination/$source_basename"

        >&2 echo "copy from image:                      $image"
        >&2 echo "path:                                 $source"
        >&2 echo "to build context path:                $destination"
        >&2 echo "original COPY line in Dockerfile:     $copy_line"
        >&2 echo "copy destination:                     $copy_destination"
        >&2 echo "dockerized COPY line:                 $docker_copy_line"
        
        cmd="$cmd | sed \"s#$copy_line#$docker_copy_line#\""
    done

    # >&2 echo "modified Dockerfile:"
    # >&2 echo "$(bash -c "$cmd")"
fi

# cmd="$cmd | tee /dev/tty"

if [ $uri = "null" ]; then
    cmd="$cmd | sudo docker build -t $image_repository$build -"
else
    cmd="$cmd | sudo docker build -t $image_repository$build -f - $uri#$branch"
fi

echo $cmd