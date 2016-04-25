#!/bin/bash

bash utils/create-image.bash dockerfiles/base base

bash utils/create-arteafacts-volume.bash

bash utils/run-job3.bash build-scripts/clone-chipster.bash
bash utils/run-job3.bash build-scripts/build-chipster.bash
bash utils/run-job3.bash build-scripts/build-chipster-web-server.bash

bash utils/run-job3.bash build-scripts/clone-chipster-web.bash
bash utils/run-job3.bash build-scripts/clone-chipster-tools.bash

bash utils/run-job3.bash build-scripts/download-tools-bin.bash

bash utils/create-image.bash dockerfiles/server server
bash utils/create-image.bash dockerfiles/comp comp server




# oc run artefacts --image 172.30.1.144:5000/chipster/comp --command sleep inf
# oc set volume dc/artefacts --add -t pvc --mount-path /mnt/artefacts --claim-name artefacts
# oc rsh $(oc get pod -l run=artefacts | grep -v NAME | cut -d " " -f 1)