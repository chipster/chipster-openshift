#!/bin/bash

set -e

# these must match with the image versions copied to the server
IMAGE_REPO="image-registry.apps.2.rahti.csc.fi/chipster-images/"
IMAGE_TAG="v4.18.1-rc4"
TOOLS_BIN_VERSION="chipster-4.17.4"

# installation directory for chipster
HOST_DIR="/media/volume/chipster"

if ! podman images | tr -s ' ' | cut -d " " -f 2 | grep $IMAGE_TAG > /dev/null; then
    echo "Error: container image version not found. "
    echo "Version configured: $IMAGE_TAG (in $BASH_SOURCE)"
    echo "Version available: (in 'podman images'):"
    podman images | tr -s ' ' | cut -d " " -f 2 | sort | uniq
    exit 1
fi

if ! [ -d $HOST_DIR/tools-bin/$TOOLS_BIN_VERSION ]; then
    echo "Error: tools-bin directory not found."
    echo "Version configured: $TOOLS_BIN_VERSION (in $BASH_SOURCE)"
    echo "Versions available (in $HOST_DIR/tools-bin):"
    ls $HOST_DIR/tools-bin
    exit 1
fi

if [ -f $HOST_DIR/conf/chipster.yaml ]; then
    postgres_password=$(cat $HOST_DIR/conf/chipster.yaml | yq '.db-pass-auth')
fi

wait_http_port () {
    # follow logs in background
    podman logs -f $2 &
    log_pid=$!
    while ! curl -s localhost:$1 > /dev/null; do
        sleep 1
    done
    kill $log_pid
}

wait_postgres () {
    podman logs -f postgres &
    log_pid=$!
    while ! podman run --rm --network podman ${IMAGE_REPO}postgresql-14:$IMAGE_TAG pg_isready -h host.containers.internal -U postgres > /dev/null; do
        sleep 1
    done
    kill $log_pid
}

stop_and_remove_all () {

    echo "stop all containers"
    podman stop --all || true

    echo "remove all containers"
    podman rm --all || true
}

start_postgres () {

    echo "start postgres"

    # --volume needs option ":U", because initdb chowns the dat adirectory
    podman run --detach --rm --network podman --name postgres \
        -e POSTGRES_PASSWORD=$postgres_password \
        --volume $HOST_DIR/db-data:/var/lib/postgresql/data:U \
        -p 5432:5432 \
        ${IMAGE_REPO}postgresql-14:$IMAGE_TAG

    wait_postgres
}