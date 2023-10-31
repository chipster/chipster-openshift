#!/bin/bash

set -e
set -o pipefail

source scripts/utils.bash

PROJECT=$(oc project -q)
DOMAIN=$(get_domain)

wait_dc auth

# check connection first, otherwise connection errors cause the users file to be overwritten
if oc rsh -c auth dc/auth hostname && oc rsh -c auth dc/auth ls /opt/chipster/security/users > /dev/null ; then
  echo "Using old accounts"
else
  echo "Create default accounts"
  # copy with "oc rsh", because oc cp would require a pod name
  
  users_path="../chipster-private/confs/$PROJECT.$DOMAIN/users"
  
  if [ ! -f $users_path ]; then
    users_path="../chipster-private/confs/chipster-all/users"
  fi
  
  echo "Paste ansible-vault password below and hit enter"
  ansible-vault view $users_path | oc rsh -c auth dc/auth bash -c "cat - > /opt/chipster/security/users"
  # ansible-vault view --vault-password-file password.txt $users_path

fi

psql auth-postgres        auth_db        'alter system set synchronous_commit to off'
psql session-db-postgres  session_db_db  'alter system set synchronous_commit to off'
oc rsh dc/auth-postgres       bash -c 'pg_ctl reload -D /var/lib/pgsql/data/userdata'
oc rsh dc/session-db-postgres bash -c 'pg_ctl reload -D /var/lib/pgsql/data/userdata'
if [ $(oc get dc job-history-postgres -o json | jq .spec.replicas) == 1 ]; then
  psql job-history-postgres job_history_db 'alter system set synchronous_commit to off'
  oc rsh dc/job-history-postgres bash -c 'pg_ctl reload -D /var/lib/pgsql/data/userdata'
fi

# create a db to influxdb
if [ $(oc get dc influxdb -o json | jq .spec.replicas) == 1 ]; then
  oc rsh dc/influxdb curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE db" -X POST
  # set 2 year retention policy. Use this command to see it:  oc rsh dc/influxdb curl 'localhost:8086/query?pretty=true' -X POST --data-binary "db=db;q=show retention policies;'"
  oc rsh dc/influxdb curl 'localhost:8086/query?pretty=true' -X POST --data-binary "q=alter retention policy autogen on db duration 104w shard duration 1w replication 1 default;'"
fi

if [ $(oc get dc grafana -o json | jq .spec.replicas) == 1 ]; then
  if [ -z ../chipster-private/confs/chipster-all/grafana-admin-password ]; then
	  grafana_password="$(cat ../chipster-private/confs/chipster-all/grafana-admin-password)"
	  oc rsh dc/grafana grafana-cli admin reset-admin-password --homepath "/usr/share/grafana" "$grafana_password"

	  curl https://grafana-$PROJECT.$DOMAIN/api/datasources -u admin:$grafana_password -X POST --data-binary '{ "name": "InfluxDB", "type": "influxdb", "url": "http://influxdb:8086", "access": "proxy", "basicAuth": false, "database": "db" }' -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-summary.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-websocket.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-load.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-rest.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-benchmark.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-replay-test.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
  fi
fi 
