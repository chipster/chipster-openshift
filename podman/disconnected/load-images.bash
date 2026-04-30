#!/bin/bash

set -e

source $(dirname "$0")/env.bash

if [ -z $1 ]; then
    echo "Usage: bash load-images.bash IMAGE_TAR_DIRECTORY"
    echo ""
    echo "Images will be stored in $HOST_DIR/podman-graphroot ."
    exit 1
fi

tar_dir="$1"

if ls $tar_dir/*.tar.zst > /dev/null; then
    echo "load images from $tar_dir"
else
    echo "error: images not found"
fi

echo "configure podman to store images in $HOST_DIR/podman-graphroot"

mkdir -p $HOST_DIR/podman-graphroot

# store containers on the volume

cat > ~/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
graphroot = "$HOST_DIR/podman-graphroot"
EOF

for image_path in $tar_dir/*.tar.zst; do
    image=${IMAGE_REPO}$(basename $image_path .tar.zst):$IMAGE_TAG

    if podman image exists $image; then
        echo "image $image exists already"
    else
        echo "load image $image"
        cat $image_path | zstd -d | podman load
    fi
done