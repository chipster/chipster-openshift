#!/bin/bash

# run only once, use "bash update_dockerfile NAME; oc start-build NAME" later
bash build-all.bash
# run if there are new volumes
bash deploy-pvc2.bash
# run if configuration has changed (and bash rollout-services.bash if running only this)
bash create-secrets.bashs
# run if the templates have changed or there are new services
bash deploy-services2.bash

bash deploy-shibboleth.bash