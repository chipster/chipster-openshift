#!/bin/bash

pushd openshift
bash generate-passwords.bash
popd

# deploy databases
bash deploy-postgres.bash

# create or update builds
bash deploy-builds.bash

pushd openshift
# run if the templates or configuration have changed or there are new services
bash deploy.bash
popd

# optional
#bash deploy-mylly-app.bash

# create default users in auth and configure grafana password and dashboards (not started with the default quota)
bash setup.bash

# download tools if you have enough storage quota
#bash download-tools-bin.bash
#bash download-tools-bin-mylly.bash