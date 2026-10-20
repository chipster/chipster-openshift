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
if dc_exists job-history-postgres && [ "$(oc get dc job-history-postgres -o json | jq .spec.replicas)" == 1 ]; then
  psql job-history-postgres job_history_db 'alter system set synchronous_commit to off'
  oc rsh dc/job-history-postgres bash -c 'pg_ctl reload -D /var/lib/pgsql/data/userdata'
fi

# create a db and users to influxdb
influxdb_secret="$(oc get secret influxdb -o json)"
influxdb_admin_password="$(echo "$influxdb_secret" | jq '.data."admin-password"' -r | base64 -d)"
influxdb_writer_password="$(echo "$influxdb_secret" | jq '.data."writer-password"' -r | base64 -d)"
influxdb_reader_password="$(echo "$influxdb_secret" | jq '.data."reader-password"' -r | base64 -d)"

if dc_exists influxdb && [ "$(oc get dc influxdb -o json | jq .spec.replicas)" == 1 ]; then
  echo "wait until InfluxDB responds"
  until oc rsh dc/influxdb curl -s -f localhost:8086/ping > /dev/null 2>&1; do sleep 2; done

  # print the response and fail if it has an error
  function influxql {
    oc rsh dc/influxdb curl -s -u "admin:$influxdb_admin_password" http://localhost:8086/query -X POST --data-urlencode "q=$1" | tee /dev/stderr | jq -e '.error == null and all(.results[]; .error == null)' > /dev/null
  }

  # InfluxDB allows creating the first admin user without credentials. Fails harmlessly if it exists already.
  oc rsh dc/influxdb curl -s http://localhost:8086/query -X POST --data-urlencode "q=CREATE USER admin WITH PASSWORD '$influxdb_admin_password' WITH ALL PRIVILEGES"
  influxql "CREATE DATABASE db"
  # set 2 year retention policy. Use this command to see it: influxql "show retention policies on db"
  influxql "alter retention policy autogen on db duration 104w shard duration 1w replication 1 default"
  # fails if the user exists with another password, which is then set below
  influxql "CREATE USER writer WITH PASSWORD '$influxdb_writer_password'" || true
  influxql "SET PASSWORD FOR writer = '$influxdb_writer_password'"
  influxql "GRANT WRITE ON db TO writer"
  # fails if the user exists with another password, which is then set below
  influxql "CREATE USER reader WITH PASSWORD '$influxdb_reader_password'" || true
  influxql "SET PASSWORD FOR reader = '$influxdb_reader_password'"
  influxql "GRANT READ ON db TO reader"
fi

if dc_exists grafana && [ "$(oc get dc grafana -o json | jq .spec.replicas)" == 1 ]; then
  grafana_password_file="../chipster-private/confs/chipster-all/grafana-admin-password"
  if [ ! -s "$grafana_password_file" ]; then
    echo "ERROR: $grafana_password_file is missing or empty, Grafana admin password not set" >&2
    exit 1
  else
	  grafana_password="$(cat "$grafana_password_file")"
	  oc rsh dc/grafana grafana-cli admin reset-admin-password --homepath "/usr/share/grafana" "$grafana_password"

	  datasource="{ \"name\": \"InfluxDB\", \"type\": \"influxdb\", \"url\": \"http://influxdb:8086\", \"access\": \"proxy\", \"isDefault\": true, \"basicAuth\": false, \"database\": \"db\", \"user\": \"reader\", \"password\": \"$influxdb_reader_password\", \"secureJsonData\": { \"password\": \"$influxdb_reader_password\" } }"
	  # update the datasource if it exists already, to keep the dashboards connected to it
	  datasource_id="$(curl -s https://grafana-$PROJECT.$DOMAIN/api/datasources/name/InfluxDB -u "admin:$grafana_password" | jq '.id // empty')"
	  if [ -n "$datasource_id" ]; then
	    curl https://grafana-$PROJECT.$DOMAIN/api/datasources/$datasource_id -u "admin:$grafana_password" -X PUT --data-binary "$datasource" -H Content-Type:application/json
	  else
	    curl https://grafana-$PROJECT.$DOMAIN/api/datasources -u "admin:$grafana_password" -X POST --data-binary "$datasource" -H Content-Type:application/json
	  fi
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u "admin:$grafana_password" -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-summary.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u "admin:$grafana_password" -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-websocket.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u "admin:$grafana_password" -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-load.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u "admin:$grafana_password" -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-rest.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u "admin:$grafana_password" -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-benchmark.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
	  curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u "admin:$grafana_password" -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-replay-test.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
  fi
fi 
