source script-utils/deploy-utils.bash

# check connection first, otherwise connection errors cause the users file to be overwritten
if oc rsh dc/auth hostname && oc rsh dc/auth ls /opt/chipster-web-server/security/users > /dev/null ; then
  echo "Using old accounts"
else
  echo Create default accounts
  # copy with "oc rsh", because oc cp would require a pod name
  cat ../chipster-private/confs/$PROJECT.$DOMAIN/users | oc rsh dc/auth bash -c "cat - > /opt/chipster-web-server/security/users"
fi

# create a db to influxdb
oc rsh dc/influxdb curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE db" -X POST

oc rsh dc/grafana grafana-cli admin reset-admin-password --homepath "/usr/share/grafana" "$(cat ../chipster-private/confs/rahti-int/grafana-admin-password)" 

grafana_password="$(cat ../chipster-private/confs/rahti-int/grafana-admin-password)"
curl https://grafana-$PROJECT.$DOMAIN/api/datasources -u admin:$grafana_password -X POST --data-binary '{ "name": "InfluxDB", "type": "influxdb", "url": "http://influxdb:8086", "access": "proxy", "basicAuth": false, "database": "db" }' -H Content-Type:application/json
curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-summary.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-websocket.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-load.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-rest.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat monitoring/dashboard-benchmark.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
