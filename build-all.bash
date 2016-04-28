#!/bin/bash

CHIPSTER_BRANCH=master
SERVER_BRANCH=master
CLIENT_BRANCH=master
TOOLS_BRANCH=master

bash utils/create-image.bash dockerfiles/base base ubuntu:16.04

bash utils/create-arteafacts-volume.bash

bash utils/run-job3.bash base build/envs.bash build/clone-chipster.bash $CHIPSTER_BRANCH
bash utils/run-job3.bash base build/envs.bash build/build-chipster.bash latest_$CHIPSTER_BRANCH 
bash utils/run-job3.bash base build/envs.bash build/build-chipster-web-server.bash $SERVER_BRANCH latest_$CHIPSTER_BRANCH

bash utils/run-job3.bash base build/envs.bash build/clone-chipster-web.bash $CLIENT_BRANCH
bash utils/run-job3.bash base build/envs.bash build/clone-chipster-tools.bash $TOOLS_BRANCH

bash utils/run-job3.bash base build/envs.bash build/download-tools-bin.bash

bash utils/create-image.bash dockerfiles/server server
bash utils/create-image.bash dockerfiles/comp comp server


# oc delete dc artefacts
# oc delete $(oc get pod -l run=artefacts | grep -v NAME | cut -d " " -f 1)
# oc run artefacts --image 172.30.1.144:5000/chipster/comp --command sleep inf
# oc set volume dc/artefacts --add -t pvc --mount-path /mnt/artefacts --claim-name artefacts
# oc rsh $(oc get pod -l run=artefacts | grep -v NAME | cut -d " " -f 1)

oc deploy auth --latest
oc deploy service-locator --latest
oc deploy session-db --latest
oc deploy file-broker --latest
oc deploy scheduler --latest
oc deploy toolbox --latest
oc deploy comp --latest
oc deploy web --latest
