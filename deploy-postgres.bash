#!/bin/bash

set -e

source scripts/utils.bash

function deploy_postgres {

  template="$1"
  name="$2"
  camel_case_name="$3"
  PROJECT="$4"
  DOMAIN="$5"
  
  db_name="$(echo $name | tr "-" "_")_db"
  
  pvc_size="$(get_deploy_config $private_config_path pvc-size-$name-postgres $PROJECT $DOMAIN)"
  
  if [ -z "$pvc_size" ]; then
    pvc_size="100Mi"
  fi

  db_password="$(oc get secret passwords -o json | jq '.data."values.json"' -r | base64 -d | jq .db.$camel_case_name.password -r)"

  # add different subproject label for databases, so that those can be kept or removed separately 
  echo "$template" \
  | jq ".labels.app=\"chipster\"" \
  | jq .objects[3].spec.template.spec.containers[0].resources.limits.cpu=\"1900m\" \
  | jq .objects[3].spec.template.spec.containers[0].resources.requests.cpu=\"1900m\" \
  | jq .objects[3].spec.template.spec.containers[0].resources.requests.memory=\"1Gi\" \
  | oc process -f - --local \
  -p POSTGRESQL_DATABASE=$db_name \
  -p DATABASE_SERVICE_NAME=$name-postgres \
  -p POSTGRESQL_PASSWORD=$db_password \
  -p POSTGRESQL_USER=user \
  -p NAMESPACE=openshift \
  -p VOLUME_CAPACITY=$pvc_size \
  -p POSTGRESQL_VERSION=9.5 \
  -p MEMORY_LIMIT=1Gi \
  | oc apply -f - 
}

PROJECT=$(oc project -q)
DOMAIN=$(get_domain)
private_config_path="../chipster-private/confs"

template="$(oc get template -n openshift postgresql-persistent -o json)" 

deploy_postgres "$template" auth auth $PROJECT $DOMAIN 
deploy_postgres "$template" session-db sessionDb $PROJECT $DOMAIN
deploy_postgres "$template" job-history jobHistory $PROJECT $DOMAIN
