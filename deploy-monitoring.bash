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

# run in base container
# git clone https://github.com/chipster/chipster-web-server.git
# npm install
# tsc
# pushd ../type-service ; npm install ; tsc ; popd 
# node src/chipster login web-server:8000 -u admin -p admin
# client get's public addresses from the service locator, but can't connect  to them
# wget https://github.com/openshift/origin/releases/download/v3.6.0/openshift-origin-client-tools-v3.6.0-c4dd4cf-linux-64bit.tar.gz
# tar -zxf openshift-origin-client-tools-v3.6.0-c4dd4cf-linux-64bit.tar.gz
# cd openshift
#  ./oc login dac-oso.csc.fi:8443 --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt --token $(cat /run/secrets/kubernetes.io/serviceaccount/token )


oc patch dc comp -p "$(cat script-utils/monitoring/resources.json)"
oc patch dc comp -p "$(cat script-utils/monitoring/monitoring-container.json)"

# oc delete  bc monitoring ; oc delete is monitoring
oc new-build . --name=monitoring -D - < dockerfiles/monitoring/Dockerfile

oc env dc comp --containers status password=FILL_IN
 
