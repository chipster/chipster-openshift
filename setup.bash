#!/bin/bash

set -e

source scripts/utils.bash

subproject="$1"

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
  echo subproject: $subproject
fi

PROJECT=$(oc project -q)
DOMAIN=$(get_domain)

wait_dc auth$subproject_postfix

# check connection first, otherwise connection errors cause the users file to be overwritten
if oc rsh dc/auth$subproject_postfix hostname && oc rsh dc/auth$subproject_postfix ls /opt/chipster-web-server/security/users > /dev/null ; then
  echo "Using old accounts"
else
  echo Create default accounts
  # copy with "oc rsh", because oc cp would require a pod name
  
  users_path="../chipster-private/confs/$PROJECT.$DOMAIN/users"
  
  if [ ! -f $users_path ]; then
    users_path="../chipster-private/confs/chipster-all/users"
  fi
  
  cat $users_path | oc rsh dc/auth$subproject_postfix bash -c "cat - > /opt/chipster-web-server/security/users"
fi

psql auth-postgres$subproject_postfix        auth_db        'alter system set synchronous_commit to off'
psql session-db-postgres$subproject_postfix  session_db_db  'alter system set synchronous_commit to off'
if [ $(oc get dc job-history-postgres$subproject_postfix -o json | jq .spec.replicas) == 1 ]; then
  psql job-history-postgres$subproject_postfix job_history_db 'alter system set synchronous_commit to off'
fi

# create a db to influxdb
if [ $(oc get dc influxdb$subproject_postfix -o json | jq .spec.replicas) == 1 ]; then
  oc rsh dc/influxdb$subproject_postfix curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE db" -X POST
fi

if [ $(oc get dc grafana$subproject_postfix -o json | jq .spec.replicas) == 1 ]; then
  oc rsh dc/grafana$subproject_postfix grafana-cli admin reset-admin-password --homepath "/usr/share/grafana" "$(cat ../chipster-private/confs/chipster-all/grafana-admin-password)"

  grafana_password="$(cat ../chipster-private/confs/rahti-int/grafana-admin-password)"
  curl https://grafana$subproject_postfix-$PROJECT.$DOMAIN/api/datasources -u admin:$grafana_password -X POST --data-binary '{ "name": "InfluxDB", "type": "influxdb", "url": "http://influxdb:8086", "access": "proxy", "basicAuth": false, "database": "db" }' -H Content-Type:application/json
  curl https://grafana$subproject_postfix-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-summary.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
  curl https://grafana$subproject_postfix-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-websocket.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
  curl https://grafana$subproject_postfix-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-load.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
  curl https://grafana$subproject_postfix-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-rest.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
  curl https://grafana$subproject_postfix-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-benchmark.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
fi 
