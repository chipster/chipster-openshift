#!/bin/bash

set -e

source scripts/utils.bash

function deploy_postgres {

  template="$1"
  subproject="$2"
  subproject_postfix="$3" 
  name="$4"
  
  db_name="$(echo $name | tr "-" "_")_db"

  # add different subproject label for databases, so that those can be kept or removed separately 
  echo "$template" \
  | jq ".labels.subproject=\"${subproject}-db\"" \
  | jq ".labels.app=\"chipster$subproject_postfix\"" \
  | oc process -f - --local \
  -p POSTGRESQL_DATABASE=$db_name \
  -p DATABASE_SERVICE_NAME=$name-postgres$subproject_postfix \
  -p POSTGRESQL_PASSWORD=$(get_db_password passwords$subproject_postfix $name) \
  -p POSTGRESQL_USER=user \
  -p NAMESPACE=openshift \
  -p VOLUME_CAPACITY=100Mi \
  -p POSTGRESQL_VERSION=9.5 \
  | oc apply -f - 
}

subproject="$1"

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
fi

template="$(oc get template -n openshift postgresql-persistent -o json)" 

deploy_postgres "$template" "$subproject" "$subproject_postfix" auth
deploy_postgres "$template" "$subproject" "$subproject_postfix" session-db
deploy_postgres "$template" "$subproject" "$subproject_postfix" job-history
