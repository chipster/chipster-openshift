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

template="$(oc get template -n openshift postgresql-persistent -o json)" 

echo "$template" | oc process -f - --local \
  -p POSTGRESQL_DATABASE=auth_db \
  -p DATABASE_SERVICE_NAME=auth-postgres \
  -p POSTGRESQL_PASSWORD=$(get_db_password auth) \
  -p POSTGRESQL_USER=user \
  -p NAMESPACE=openshift \
  -p VOLUME_CAPACITY=100Mi \
  -p POSTGRESQL_VERSION=9.5 \
  | oc apply -f - 

# for some reason glusterfs services won't get created, if we create pvcs too fast
if [ -z "$is_fast" ]; then  
  wait_pvc_bound auth-postgres
fi
  
echo "$template" | oc process -f - --local \
  -p POSTGRESQL_DATABASE=session_db_db \
  -p DATABASE_SERVICE_NAME=session-db-postgres \
  -p POSTGRESQL_PASSWORD=$(get_db_password session-db) \
  -p POSTGRESQL_USER=user \
  -p NAMESPACE=openshift \
  -p VOLUME_CAPACITY=1Gi \
  -p POSTGRESQL_VERSION=9.5 \
  | oc apply -f -

if [ -z "$is_fast" ]; then  
  wait_pvc_bound session-db-postgres
fi
  
echo "$template" | oc process -f - --local \
  -p POSTGRESQL_DATABASE=job_history_db \
  -p DATABASE_SERVICE_NAME=job-history-postgres \
  -p POSTGRESQL_PASSWORD=$(get_db_password job-history) \
  -p POSTGRESQL_USER=user \
  -p NAMESPACE=openshift \
  -p VOLUME_CAPACITY=100Mi \
  -p POSTGRESQL_VERSION=9.5 \
  | oc apply -f -

if [ -z "$is_fast" ]; then
  wait_pvc_bound job-history-postgres
fi

if [ -z "$is_fast" ]; then
  psql auth-postgres        auth_db        'alter system set synchronous_commit to off'
  psql session-db-postgres  session_db_db  'alter system set synchronous_commit to off'
  psql job-history-postgres job_history_db 'alter system set synchronous_commit to off'
fi
