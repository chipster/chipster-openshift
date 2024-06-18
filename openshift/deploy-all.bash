#!/bin/bash

bash generate-passwords.bash

# deploy databases
#bash deploy-postgres.bash

# create or update builds
bash deploy-builds.bash


# run if the templates or configuration have changed or there are new services
bash deploy.bash

# create default users in auth and configure grafana password and dashboards (not started with the default quota)
bash setup.bash

# download tools if you have enough storage quota
#bash download-tools-bin.bash
