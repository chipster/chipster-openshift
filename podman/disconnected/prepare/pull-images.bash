#!/bin/bash

set -e

if [ -z $1 ]; then
	echo "Usage bash pull-images VERSION"
	echo ""
	echo "Available versions: "
	curl -s https://image-registry.apps.2.rahti.csc.fi/v2/chipster-images/base/tags/list -H "Authorization: Bearer anonymous" | jq '.tags[]' -r | sort --version-sort
	exit 1
fi

version="$1"
image_repo="image-registry.apps.2.rahti.csc.fi/chipster-images-dev"

mkdir -p $version

for image in $(find ~/git/chipster-openshift/kustomize/builds -maxdepth 1 -mindepth 1 -type d | cut -d "/" -f 8); do 
	echo "pull $image"
	podman run --volume $(pwd)/$version:/mnt/img quay.io/skopeo/stable copy \
		docker://$image_repo/$image:$version \
		docker-archive:/mnt/img/${image}.tar:$image_repo/$image:$version || true
done

for file in $version/*.tar; do
	echo "compress $file"
	cat $file | pv | zstd > $file.zst
	rm $file
done