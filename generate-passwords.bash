#!/bin/bash

source script-utils/deploy-utils.bash

echo "$DOMAIN"
echo "Create passwords for $PROJECT.$DOMAIN"
echo

set -e

oc create secret generic passwords \
  --from-literal=auth-db-password=$(generate_password) \
  --from-literal=session-db-db-password=$(generate_password) \
  --from-literal=job-history-db-password=$(generate_password)
  
authenticated_services=$(cat ../chipster-web-server/src/main/resources/chipster-defaults.yaml | grep ^service-password- | cut -d : -f 1 | sed s/service-password-//)

for service in $authenticated_services; do
  oc get secret passwords -o json | jq .data.\"service-password-$service\"=\"$(generate_password | base64)\" | oc replace secret passwords -f -
done