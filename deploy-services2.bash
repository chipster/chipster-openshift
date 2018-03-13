#!/bin/bash

set -e

# parse the current project name
function get_project {
  oc project -q
}

# parse the current project domain (i.e. the address of this OpenShift)
function get_domain {
  #oc status | grep "In project" | cut -d " " -f 6 | cut -d / -f 3 | cut -d : -f 1
  echo "rahti-int-app.csc.fi"
}

export PROJECT=$(get_project)
export DOMAIN=$(get_domain)

if [[ $(oc get dc) ]] || [[ $(oc get service -o name | grep -v glusterfs-dynamic-) ]] || [[ $(oc get routes) ]] ; then
  echo "The project is not empty"
  echo ""
  echo "The scirpt will continue, but it won't delete any extra deployments you possibly have."
  echo "Run the following command to remove all deployments:"
  echo ""
  echo '    oc delete dc --all; oc delete routes --all; oc delete pods --all; for s in $(oc get service -o name | grep -v glusterfs-dynamic-); do oc delete $s; done'
  echo ""
  echo "and if your want to remove volumes too:"
  echo ""
  echo "    oc delete pvc --all"
  echo ""
fi

echo "Generating deployment configs etc."
bash create-deployments.bash

# it's faster to get the list just once
old_dcs="$(oc get dc -o name)"
old_services="$(oc get service -o name)"
old_routes="$(oc get route -o name)"

for f in generated/deployments/*.yaml; do
  # match only to the end of the line to separate "auth" and "auth-api"
  # quotes in the echo keep the new lines and the (second) dollar in the grep matches it
  if echo "$old_dcs" | grep -q "$(basename $f .yaml)$" ; then
    oc replace -f $f &
  else
    oc create -f $f &
  fi
done

wait

for f in deployments/patches/*.yaml; do
  name=$(basename $f .yaml)
  oc patch dc $name -p "$(cat $f)" &
done

wait

# replace doesn't work for services, so delete all
for f in generated/services/*.yaml; do
  name=$(basename $f .yaml)
  if echo "$old_services" | grep -q "$name$" ; then
    oc delete service "$name" &
  fi
done

wait

for f in generated/services/*.yaml; do
  oc create -f $f &
done

wait

for f in generated/routes/*.yaml; do
  if echo "$old_routes" | grep -q "$(basename $f .yaml)$" ; then
    oc replace -f $f &
  else
     oc create -f $f &
   fi
done

wait

# check connection first, otherwise connection errors cause the users file to be overwritten
if oc rsh dc/auth hostname && oc rsh dc/auth ls /opt/chipster-web-server/security/users > /dev/null ; then
  echo "Using old accounts"
else
  echo Create default accounts
  # copy with "oc rsh", because oc cp would require a pod name
  cat ../chipster-private/confs/rahti-int/users | oc rsh dc/auth bash -c "cat - > /opt/chipster-web-server/security/users"
fi

# create a db to influxdb
oc rsh dc/influxdb curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE db" -X POST

oc rsh dc/grafana grafana-cli admin reset-admin-password --homepath "/usr/share/grafana" "$(cat ../chipster-private/confs/rahti-int/grafana-admin-password)" 

grafana_password="$(cat ../chipster-private/confs/rahti-int/grafana-admin-password)"
curl https://grafana-$PROJECT.$DOMAIN/api/datasources -u admin:$grafana_password -X POST --data-binary '{ "name": "InfluxDB", "type": "influxdb", "url": "http://influxdb:8086", "access": "proxy", "basicAuth": false, "database": "db" }' -H Content-Type:application/json
curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat script-utils/monitoring/dashboard-summary.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat script-utils/monitoring/dashboard-websocket.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat script-utils/monitoring/dashboard-load.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json
curl https://grafana-$PROJECT.$DOMAIN/api/dashboards/db -u admin:$grafana_password -X POST --data-binary "{ \"dashboard\": $(cat script-utils/monitoring/dashboard-rest.json | sed 's/${DS_INFLUXDB}/InfluxDB/g') }" -H Content-Type:application/json


echo '------------------------------------------------------------------------------'
echo '# 1) Download tools by running the following commands:'
echo '# login to the container'
echo 'oc rsh dc/base bash'
echo 'mkdir -p /mnt/tools/current'
echo 'cd /mnt/tools/current'
echo ''
echo '# Optionally, convert the tools.tar.gz to lz4 on the build or aux server'
echo 'cat tools.tar.gz | gunzip | lz4 > tools.tar.lz4 &'
echo ''
echo '# download and extract tool binaries'
echo 'curl http://vm0151.kaj.pouta.csc.fi/artefacts/create_tools_images/chipster-3.12.3/tools.tar.gz | tar -zx >> log.txt 2>&1 &'
echo 'or'
echo 'curl http://vm0151.kaj.pouta.csc.fi/artefacts/create_tools_images/chipster-3.12.3/tools.tar.lz4 | lz4 -d | tar -x >> log.txt 2>&1 &'
echo ''
echo '# logout from the container'
echo 'exit'
echo ''
echo '# delete the container'
echo 'oc delete dc base'
echo ''
echo '# Optionally, run the following in the container to fix dstat and other programs requiring a username'
echo 'bash /fix-username.bash'
echo '------------------------------------------------------------------------------'
