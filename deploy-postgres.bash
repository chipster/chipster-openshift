#!/bin/bash

set -e

source scripts/utils.bash

function deploy_postgres {

  template="$1"
  subproject="$2"
  subproject_postfix="$3" 
  name="$4"
  PROJECT="$5"
  DOMAIN="$6"
  
  db_name="$(echo $name | tr "-" "_")_db"
  
  if [ -n "$subproject" ]; then
    subproject_label="${subproject}-db"
  else
    subproject_label="db"
  fi
  
  pvc_size="$(get_deploy_config $private_config_path pvc-size-$name-postgres $PROJECT $DOMAIN)"
  
  if [ -z "$pvc_size" ]; then
    pvc_size="100Mi"
  fi

  # add different subproject label for databases, so that those can be kept or removed separately 
  echo "$template" \
  | jq ".labels.subproject=\"${subproject_label}\"" \
  | jq ".labels.app=\"chipster$subproject_postfix\"" \
  | jq .objects[3].spec.template.spec.containers[0].resources.limits.cpu=\"1900m\" \
  | jq .objects[3].spec.template.spec.containers[0].resources.requests.cpu=\"1900m\" \
  | jq .objects[3].spec.template.spec.containers[0].resources.requests.memory=\"1Gi\" \
  | oc process -f - --local \
  -p POSTGRESQL_DATABASE=$db_name \
  -p DATABASE_SERVICE_NAME=$name-postgres$subproject_postfix \
  -p POSTGRESQL_PASSWORD=$(get_db_password passwords$subproject_postfix $name) \
  -p POSTGRESQL_USER=user \
  -p NAMESPACE=openshift \
  -p VOLUME_CAPACITY=$pvc_size \
  -p POSTGRESQL_VERSION=9.5 \
  -p MEMORY_LIMIT=1Gi \
  | oc apply -f - 
}

subproject="$1"

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
fi

PROJECT=$(oc project -q)
DOMAIN=$(get_domain)
private_config_path="../chipster-private/confs"

template="$(oc get template -n openshift postgresql-persistent -o json)" 

deploy_postgres "$template" "$subproject" "$subproject_postfix" auth $PROJECT $DOMAIN
deploy_postgres "$template" "$subproject" "$subproject_postfix" session-db $PROJECT $DOMAIN
deploy_postgres "$template" "$subproject" "$subproject_postfix" job-history $PROJECT $DOMAIN
