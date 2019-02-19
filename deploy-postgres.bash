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

is_fast="$1"
subproject="$2"

if [ -z $subproject ]; then
  postfix=""
else
  postfix="-$subproject"
fi

template="$(oc get template -n openshift postgresql-persistent -o json)" 

echo "$template" | oc process -f - --local \
  -p POSTGRESQL_DATABASE=auth_db \
  -p DATABASE_SERVICE_NAME=auth-postgres$postfix \
  -p POSTGRESQL_PASSWORD=$(get_db_password passwords$postfix auth) \
  -p POSTGRESQL_USER=user \
  -p NAMESPACE=openshift \
  -p VOLUME_CAPACITY=100Mi \
  -p POSTGRESQL_VERSION=9.5 \
  | oc apply -f - 

# for some reason glusterfs services won't get created, if we create pvcs too fast
if [ -z "$is_fast" ]; then  
  wait_pvc_bound auth-postgres$postfix
fi
  
echo "$template" | oc process -f - --local \
  -p POSTGRESQL_DATABASE=session_db_db \
  -p DATABASE_SERVICE_NAME=session-db-postgres$postfix \
  -p POSTGRESQL_PASSWORD=$(get_db_password passwords$postfix session-db) \
  -p POSTGRESQL_USER=user \
  -p NAMESPACE=openshift \
  -p VOLUME_CAPACITY=1Gi \
  -p POSTGRESQL_VERSION=9.5 \
  | oc apply -f -

if [ -z "$is_fast" ]; then  
  wait_pvc_bound session-db-postgres$postfix
fi
  
echo "$template" | oc process -f - --local \
  -p POSTGRESQL_DATABASE=job_history_db \
  -p DATABASE_SERVICE_NAME=job-history-postgres$postfix \
  -p POSTGRESQL_PASSWORD=$(get_db_password passwords$postfix job-history) \
  -p POSTGRESQL_USER=user \
  -p NAMESPACE=openshift \
  -p VOLUME_CAPACITY=100Mi \
  -p POSTGRESQL_VERSION=9.5 \
  | oc apply -f -

if [ -z "$is_fast" ]; then
  wait_pvc_bound job-history-postgres$postfix
fi

if [ -z "$is_fast" ]; then
  psql auth-postgres$postfix        auth_db        'alter system set synchronous_commit to off'
  psql session-db-postgres$postfix  session_db_db  'alter system set synchronous_commit to off'
  psql job-history-postgres$postfix job_history_db 'alter system set synchronous_commit to off'
fi
