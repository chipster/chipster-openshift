#!/bin/bash

# run only once, use "bash update-dockerfile NAME; oc start-build NAME" later
bash build-all.bash

# run if configuration has changed (and bash rollout-services.bash if running only this)
bash create-secrets.bash

# run if the templates have changed or there are new services
bash deploy-services.bash

# run if there are new volumes (assumes script-utils/process-templates.bash is run by the previous command)
bash create-pvcs.bash

# optional
#bash deploy-shibboleth.bash

# create default users in auth and cofigure grafana password and dasboards
bash setup.bash

# donwload tools if you have enough storage quota
#bash download-tools-bin.bash