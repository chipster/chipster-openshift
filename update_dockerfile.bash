#!/bin/bash

if [ -z "$1" ]; then 
	echo "Usage: bash update_dockerfile.bash BUILD_NAME"
	echo ""
	echo "Replaces the dockerfile in given the OpenShfit build with the file dockerfiles/BUILD_NAME/Dockerfile"
	echo "" 
	exit 1 
fi

build_name=$1	
oc get bc $build_name -o json | jq .spec.source.dockerfile="$(cat  dockerfiles/$build_name/Dockerfile | jq -s -R .)" | oc replace bc $build_name -f -	
