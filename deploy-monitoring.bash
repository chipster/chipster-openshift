#!/bin/bash

source script-utils/deploy-utils.bash

# deploy Influxdb from the official image
oc new-app --docker-image=influxdb
oc set volume dc/influxdb --add --name influxdb -t pvc --mount-path /var/lib/influxdb --claim-name=influxdb --claim-size=4 --overwrite

# build and deploy Grafana
oc new-build --name=grafana -D - < dockerfiles/grafana/Dockerfile --to grafana && retry oc logs -f bc/grafana
oc new-app grafana
oc set volume dc/grafana --add --name grafana -t pvc --mount-path /usr/share/grafana/data --claim-name=grafana --claim-size=4 --overwrite
oc expose dc grafana --port=3000
oc expose service grafana

echo "# run in influxdb container to create the database"
echo 'curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE db" -X POST'
echo ""
echo "# configure grafana"
echo "# Data source type: InfluxDB"
echo "# Http Url: http://influxdb:8086"
echo "# Access: proxy"
echo "# Database: db"
echo ""

# create the build config
# oc delete  bc monitoring ; oc delete is monitoring
oc new-build . --name=monitoring -D - < dockerfiles/monitoring/Dockerfile && retry oc logs -f bc/monitoring

# in case you want to run the build with the local files later
# oc start-build monitoring --from-dir="." --follow

# add the second container called "status" for collecting monitoring information

for role in auth comp file-broker scheduler service-locator session-db session-worker toolbox type-service web-server; do 	
	echo $role

	# configure lower resource limits to make space for the second container	
	oc get $d -o json | jq '.spec.template.spec.containers[0].resources={ "limits": { "cpu": "1900m", "memory": "1Gi"}, "requests": { "cpu": "200m", "memory": "100Mi"}}' | oc replace $d -f -
	
	# add the new container json to the deployment config
	oc get dc $role -o json | jq '.spec.template.spec.containers[1]='"$(cat script-utils/monitoring/monitoring-container.json)" | oc replace dc $role -f -
	
	# get the admin port of this service from the config defaults	
	admin_port=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-admin-bind-$role | cut -d ":" -f 4)
	
	# configure the status container using environment variables
	oc env dc $role --containers status admin_port=$admin_port
	oc env dc $role --containers status role=$role
	oc env dc $role --containers status password=$password
	
	# configure a health check
	oc set probe dc/$role --readiness -- curl --fail http://127.0.0.1:${admin_port}/admin/alive
	
done

# allow comp to use more resources
oc get dc comp -o json | jq '.spec.template.spec.containers[0].resources={ "limits": { "cpu": "1900m", "memory": "7900Mi"}, "requests": { "cpu": "200m", "memory": "100Mi"}}' | oc replace dc comp -f -

# configure health checks for databases
oc set probe dc/auth-h2 --readiness --open-tcp=1521
oc set probe dc/session-db-h2 --readiness --open-tcp=1521
