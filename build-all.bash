#!/bin/bash

set -x
set -e

source scripts/utils.bash

export PROJECT=$(get_project)
export DOMAIN=$(get_domain)

branch="$1"

if [ -z "$branch" ]; then
  echo Error: branch not set.
  echo ""
  echo Usage: build-all.bash BRANCH
  echo 
  exit 1
fi

# from ubuntu
oc new-build --name base -D - < dockerfiles/base/Dockerfile && retry oc logs -f bc/base &
oc new-build --name=grafana -D - < dockerfiles/grafana/Dockerfile --to grafana && retry oc logs -f bc/grafana &
wait
sleep 1

# from base
oc new-build --name comp-base -D - < dockerfiles/comp-base/Dockerfile  && retry oc logs -f bc/comp-base &
oc new-build --name h2 . -D - < dockerfiles/h2/Dockerfile  && retry oc logs -f bc/comp &
oc new-build . --name=monitoring -D - < dockerfiles/monitoring/Dockerfile && retry oc logs -f bc/monitoring &
oc new-build --name chipster-web-server-js https://github.com/chipster/chipster-web-server.git#$branch -D - < dockerfiles/chipster-web-server-js/Dockerfile && retry oc logs -f bc/chipster-web-server-js &
oc new-build --name chipster https://github.com/chipster/chipster.git#$branch -D - < dockerfiles/chipster/Dockerfile && retry oc logs -f bc/chipster &
wait
sleep 1

# from comp-base
oc new-build --name comp --source-image=chipster-web-server --source-image-path=/opt/chipster-web-server:chipster-web-server -D - < dockerfiles/comp/Dockerfile  && retry oc logs -f bc/comp &

# run serially
oc new-build --name chipster-web-server https://github.com/chipster/chipster-web-server.git#$branch -D - < dockerfiles/chipster-web-server/Dockerfile  && retry oc logs -f bc/chipster-web-server
#oc new-build --name toolbox https://github.com/chipster/chipster-tools.git -D - < dockerfiles/toolbox/Dockerfile && retry oc logs -f bc/toolbox
oc new-build --name web-server https://github.com/chipster/chipster-web.git#$branch -D - < dockerfiles/web-server/Dockerfile && retry oc logs -f bc/web-server

# Mylly
oc new-build --name comp-mylly -D - < dockerfiles/comp-mylly/Dockerfile  && retry oc logs -f bc/comp &
oc new-build --name toolbox-mylly https://github.com/CSCfi/Kielipankki-mylly.git#dev-tools -D - < dockerfiles/toolbox/Dockerfile && retry oc logs -f bc/toolbox-mylly

# We need both tools and manual from the toolbox-mylly image, but the oc command takes only one source-image-path.
# Use it to get the tools and configure the image change trigger.
oc new-build --name toolbox https://github.com/chipster/chipster-tools.git -D - \
  --source-image=toolbox-mylly --source-image-path=/opt/chipster-web-server/tools/kielipankki/:tools/ \
  < dockerfiles/toolbox/Dockerfile
  
# Modify the build config to copy also the manual
#TODO The files end up to /opt/chipster-web/src/assets/manual/kielipankki/manual. What creates the last manual folder?
oc get bc toolbox -o json | jq '.spec.source.images[0].paths[1]={"destinationDir": "manual/kielipankki/", "sourcePath": "/opt/chipster-web/src/assets/manual/"}' | oc replace bc toolbox -f -
oc start-build toolbox --follow


echo ""
echo "# Build automatically on push"
echo ""
echo "# Go to the OpenShift's Configuration tab of each build which has a GitHub source, copy the Github webhook URL" 
echo "# and paste it to the GitHub's settings page of the repository. Content type should be Application/json"
echo ""
echo "# How to update builds later?"
echo ""
echo "# Replace the dockerfile with your local version"
echo "update_dockerfile BUILD_NAME"
echo ""
echo "# Build the latest github code"
echo "oc start-build bc/BUILD_NAME --follow"
echo ""
echo "# Build your local code"
echo "oc start-build BUILD_NAME --from-dir ../REPOSITORY --follow"
echo ""
