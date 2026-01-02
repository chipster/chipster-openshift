#!/bin/bash

set -e

source $(dirname "$0")/env.bash

stop_and_remove_all

start_postgres

shared_options="--detach --rm --network podman --volume $HOST_DIR/conf:/opt/chipster/conf --user 1000"

# auth, service-locator and session-db have to be started in this order

# auth has a volume "security" for user accounts
podman run $shared_options --name auth -p 8002:8002 -p 8102:8102 -e JAVA_CLASS=fi.csc.chipster.auth.AuthenticationService --volume $HOST_DIR/security:/opt/chipster/security ${IMAGE_REPO}chipster-web-server-java:$IMAGE_TAG
wait_http_port 8002 auth

podman run $shared_options --name service-locator -p 8003:8003 -p 8103:8103 -e JAVA_CLASS=fi.csc.chipster.servicelocator.ServiceLocator ${IMAGE_REPO}chipster-web-server-java:$IMAGE_TAG
wait_http_port 8003 service-locator

# session-db has one extra port for WebSockets
podman run $shared_options --name session-db -p 8004:8004 -p 8104:8104 -p 8005:8005 -e JAVA_CLASS=fi.csc.chipster.sessiondb.SessionDb ${IMAGE_REPO}chipster-web-server-java:$IMAGE_TAG
wait_http_port 8004 session-db


# other components can be started in any order

podman run $shared_options --name session-worker -p 8009:8009 -p 8109:8109 -e JAVA_CLASS=fi.csc.chipster.sessionworker.SessionWorker ${IMAGE_REPO}chipster-web-server-java:$IMAGE_TAG
wait_http_port 8009 session-worker

podman run $shared_options --name file-broker -p 8007:8007 -p 8107:8107 -e JAVA_CLASS=fi.csc.chipster.filebroker.FileBroker ${IMAGE_REPO}chipster-web-server-java:$IMAGE_TAG
wait_http_port 8007 file-broker

# file-storage has a volume "storage" for persistence
podman run $shared_options --name file-storage -p 8016:8016 -p 8116:8116 -e JAVA_CLASS=fi.csc.chipster.filestorage.FileStorage --volume $HOST_DIR/storage:/opt/chipster/storage ${IMAGE_REPO}chipster-web-server-java:$IMAGE_TAG
wait_http_port 8016 file-storage

# scheduler needs a Podman socket to start new containers
podman run $shared_options --name scheduler -p 8006:8006 -p 8106:8106 --volume /run/user/$UID/podman/podman.sock:/run/user/1000/podman/podman.sock:U ${IMAGE_REPO}scheduler:$IMAGE_TAG
wait_http_port 8006 scheduler

# toolbox needs a volume "tools-bin" to fill in genome versions 
# conf has to be mounted again, because toolbox is running in different directory (/opt/chipster/toolbox instead of /opt/chipster), because we have two different directories named "tools"
podman run $shared_options --name toolbox -p 8008:8008 -p 8108:8108 --volume $HOST_DIR/tools-bin/$TOOLS_BIN_VERSION:/opt/chipster/tools --volume $HOST_DIR/conf:/opt/chipster/toolbox/conf ${IMAGE_REPO}toolbox:$IMAGE_TAG
wait_http_port 8008 toolbox

podman run $shared_options --name web-server -p 8000:8000 -p 8100:8100 ${IMAGE_REPO}web-server:$IMAGE_TAG
wait_http_port 8000 web-server

podman run $shared_options --name type-service -p 8010:8010 -p 8110:8110 ${IMAGE_REPO}chipster-web-server-js:$IMAGE_TAG
wait_http_port 8010 type-service

# show all containers
podman ps

echo ""
echo "Opening http://localhost:8000/login in Firefox. Please wait..."
echo ""

firefox http://localhost:8000/login &