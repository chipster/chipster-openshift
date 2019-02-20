#!/bin/bash

# run only once, takes about 30 minutes
# - update one: bash update-dockerfile NAME; oc start-build NAME
# - update all: update-all-builds.bash
# - remove all: oc delete build --all; oc delete imagestream --all
bash build-all.bash master

bash deploy-all.bash