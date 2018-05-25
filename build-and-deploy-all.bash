#!/bin/bash

# run only once, takes about 30 minutes
# - update one: bash update-dockerfile NAME; oc start-build NAME
# - update all: update-all-builds.bash
# - remove all: oc delete build --all; oc delete imagestream --all
bash build-all.bash master

# run only once, because we can't change the db password without deleting the db
bash generate-passwords.bash

# run if there are new volumes
# - remove all (assuming you have already removed all other services): oc delete pvc --all oc delete service --all
bash create-pvcs.bash

# run if configuration has changed (and bash rollout-services.bash if running only this)
bash create-secrets.bash

# run if the templates have changed or there are new services
# - remove all: bash remove-all-services.bash
bash deploy-services.bash

# run always after create-secrets.bash
bash rollout-services.bash

# optional
#bash deploy-shibboleth.bash

# create default users in auth and configure grafana password and dashboards (not started with the default quota)
bash setup.bash

# download tools if you have enough storage quota
#bash download-tools-bin.bash