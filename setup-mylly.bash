#!/bin/bash

set -e

oc new-build --name toolbox-mylly https://github.com/CSCfi/Kielipankki-mylly.git#dev-tools -D - < dockerfiles/toolbox/Dockerfile && sleep 1 && oc logs -f bc/toolbox-mylly

oc delete bc toolbox
oc delete is toolbox

# We need both tools and manual from the toolbox-mylly image, but the oc command takes only one source-image-path.
# Use it to get the tools and configure the image change trigger.
oc new-build --name toolbox https://github.com/chipster/chipster-tools.git -D - \
  --source-image=toolbox-mylly --source-image-path=/opt/chipster-web-server/tools/kielipankki/:tools/ \
  < dockerfiles/toolbox/Dockerfile
  
# Modify the build config to copy also the manual
#TODO The files end up to /opt/chipster-web/src/assets/manual/kielipankki/manual. What creates the last manual folder?
oc get bc toolbox -o json | jq '.spec.source.images[0].paths[1]={"destinationDir": "manual/kielipankki/", "sourcePath": "/opt/chipster-web/src/assets/manual/"}' | oc replace bc toolbox -f -
oc start-build toolbox --follow

bash rollout-services.bash