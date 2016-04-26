#!/bin/bash

bash utils/create-image.bash dockerfiles/base base

bash utils/create-arteafacts-volume.bash

bash utils/run-job3.bash build-scripts/clone-chipster.bash base openshift
bash utils/run-job3.bash build-scripts/build-chipster.bash base latest_openshift
# chipster-web-server branch and build of the old chipster project 
bash utils/run-job3.bash build-scripts/build-chipster-web-server.bash base openshift latest_openshift

bash utils/run-job3.bash build-scripts/clone-chipster-web.bash base openshift
bash utils/run-job3.bash build-scripts/clone-chipster-tools.bash base openshift

bash utils/run-job3.bash build-scripts/download-tools-bin.bash base

bash utils/create-image.bash dockerfiles/server server
bash utils/create-image.bash dockerfiles/comp comp server


# oc delete dc artefacts
# oc delete $(oc get pod -l run=artefacts | grep -v NAME | cut -d " " -f 1)
# oc run artefacts --image 172.30.1.144:5000/chipster/comp --command sleep inf
# oc set volume dc/artefacts --add -t pvc --mount-path /mnt/artefacts --claim-name artefacts
# oc rsh $(oc get pod -l run=artefacts | grep -v NAME | cut -d " " -f 1)