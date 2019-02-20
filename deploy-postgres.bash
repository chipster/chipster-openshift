#!/bin/bash

set -e

source scripts/utils.bash

function wait_pvc_bound {
  pvc="$1"
  
  phase=""
  
  while [ "$phase" != "Bound" ]; do
  	phase=$(oc get pvc $pvc -o json | jq .status.phase -r)
    echo "waiting pvc $pvc phase $phase to become Bound" 
    sleep 1
  done
}

function psql {
  service="$1"
  db="$2"
  sql="$3"
  
  wait_dc "$service"
  
  oc rsh dc/$service bash -c "psql -c \"$sql\""
}

function deploy_postgres {

  template="$1"
  subproject="$2"
  is_fast="$3"
  name="$4"
  
  db_name="$(echo $name | tr "-" "_")_db"

  echo "$template" \
  | jq ".labels.subproject=\"$subproject\"" \
  | jq ".labels.app=\"${name}-postgres\"" \
  | oc process -f - --local \
  -p POSTGRESQL_DATABASE=$db_name \
  -p DATABASE_SERVICE_NAME=$name-postgres$postfix \
  -p POSTGRESQL_PASSWORD=$(get_db_password passwords$postfix $name) \
  -p POSTGRESQL_USER=user \
  -p NAMESPACE=openshift \
  -p VOLUME_CAPACITY=100Mi \
  -p POSTGRESQL_VERSION=9.5 \
  | oc apply -f - 

  # for some reason glusterfs services won't get created, if we create pvcs too fast
  if [ -z "$is_fast" ]; then  
    wait_pvc_bound $name-postgres$postfix
  fi
}

is_fast="$1"
subproject="$2"

if [ -z $subproject ]; then
  postfix=""
else
  postfix="-$subproject"
fi

template="$(oc get template -n openshift postgresql-persistent -o json)" 

deploy_postgres "$template" "$subproject" "$is_fast" auth
deploy_postgres "$template" "$subproject" "$is_fast" session-db
deploy_postgres "$template" "$subproject" "$is_fast" job-history

if [ -z "$is_fast" ]; then
  psql auth-postgres$postfix        auth_db        'alter system set synchronous_commit to off'
  psql session-db-postgres$postfix  session_db_db  'alter system set synchronous_commit to off'
  psql job-history-postgres$postfix job_history_db 'alter system set synchronous_commit to off'
fi
