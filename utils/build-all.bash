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