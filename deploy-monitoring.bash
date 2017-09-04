oc new-app --docker-image=influxdb

oc set volume dc/influxdb --add --name influxdb -t pvc --mount-path /var/lib/influxdb --claim-name=influxdb --claim-size=4 --overwrite

oc delete is grafana ; oc delete bc grafana ; oc new-build --name=grafana -D - < dockerfiles/grafana/Dockerfile --to grafana
oc delete dc grafana ; oc delete service grafana ; oc new-app grafana

//oc set volume dc/grafana --add -t emptyDir --mount-path /usr/share/grafana/data
oc set volume dc/grafana --add --name grafana -t pvc --mount-path /usr/share/grafana/data --claim-name=grafana --claim-size=4 --overwrite
oc expose dc grafana --port=3000
oc expose service grafana


# run in influxdb container
# curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE db" -X POST

# configure grafana:
# Data source type: InfluxDB
# Http Url: http://influxdb:8086
# Access: proxy
# Database: db

# create the build config
# oc delete  bc monitoring ; oc delete is monitoring
oc new-build . --name=monitoring -D - < dockerfiles/monitoring/Dockerfile

# run the build with the local files
oc start-build monitoring --from-dir="." --follow

# deploy everything

for d in $(oc get dc -o name); do oc deploy $d --latest; done

# add the second container

for role in auth comp file-broker scheduler service-locator session-db session-worker toolbox type-service web-server; do 	
	echo $role
	oc get dc $role -o json | jq '.spec.template.spec.containers[1]='"$(cat script-utils/monitoring/monitoring-container.json)" | oc replace dc $role -f -
	
	admin_port=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-admin-bind-$role | cut -d ":" -f 4)
	
	oc env dc $role --containers status admin_port=$admin_port
	oc env dc $role --containers status role=$role
	oc env dc $role --containers status password=$password
	
done

# configure lower resource limits to make space for the second container

for d in $(oc get dc -o name); do 
	echo $d;
	# deployment
	oc get $d -o json | jq '.spec.strategy.resources={ "limits": { "cpu": "1", "memory": "1Gi"}}' | oc replace $d -f -
	# service 
	oc get $d -o json | jq '.spec.template.spec.containers[0].resources={ "limits": { "cpu": "1900m", "memory": "1Gi"}, "requests": { "cpu": "200m", "memory": "100Mi"}}' | oc replace $d -f -
	# monitoring
	oc get $d -o json | jq '.spec.template.spec.containers[1].resources={ "limits": { "cpu": "100m", "memory": "50Mi"}, "requests": { "cpu": "100m", "memory": "10Mi"}}' | oc replace $d -f -
done

oc get dc comp -o json | jq '.spec.template.spec.containers[0].resources={ "limits": { "cpu": "1900m", "memory": "7900Mi"}, "requests": { "cpu": "200m", "memory": "100Mi"}}' | oc replace dc comp -f -

# configure health checks

for role in auth comp file-broker scheduler service-locator session-db session-worker toolbox type-service web-server; do 	
	echo $role
	
	admin_port=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-admin-bind-$role | cut -d ":" -f 4)
	
	oc set probe dc/$role --readiness -- curl --fail http://127.0.0.1:${admin_port}/admin/alive
	
done

oc set probe dc/auth-h2 --readiness --open-tcp=1521
oc set probe dc/session-db-h2 --readiness --open-tcp=1521
