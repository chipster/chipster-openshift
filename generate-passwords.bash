#!/bin/bash

source script-utils/deploy-utils.bash

echo "$DOMAIN"
echo "Create passwords for $PROJECT.$DOMAIN"
echo

set -e

oc create secret generic passwords \
  --from-literal=auth-db-password=$(generate_password) \
  --from-literal=session-db-db-password=$(generate_password)