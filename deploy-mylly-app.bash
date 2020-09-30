set -e

# make images web-server-mylly and monitoring "shared" in Rahti registry

backend="$1"

if [ -z $backend ]; then
	echo "Usage:     bash deploy-mylly-app.bash BACKEND"
	echo "  Example: bash deploy-mylly-app.bash chipster.rahtiapp.fi"
	exit 1
fi

source scripts/utils.bash

PROJECT=$(get_project)
DOMAIN=$(get_domain)

backend_project="$(echo $backend | cut -d "." -f 1)"
backend_domain="$(echo $backend | cut -d "." -f 2-)"

# we can use the images and configs from the other project only if they are in the same Openshift installation
if [[ $backend_domain != "$DOMAIN" ]]; then  
  echo "The backend domain $backend_domain is different from the current domain $DOMAIN"
  exit 1
fi

echo "get images and configs from project $backend_project"

# probably we want the same firewall rules as the backend project
private_config_path="../chipster-private/confs"
ip_whitelist_api="$(get_deploy_config $private_config_path ip-whitelist-api $backend_project $DOMAIN)"
ip_whitelist_admin="$(get_deploy_config $private_config_path ip-whitelist-admin $backend_project $DOMAIN)"

echo "update DeploymentConfig"
oc process -f templates/java-server/java-server-dc.yaml --local \
-p NAME="web-server-mylly" \
-p API_PORT=8000 \
-p ADMIN_PORT=8100 \
-p JAVA_CLASS="fi.csc.chipster.web.WebServer" \
-p PROJECT=$PROJECT \
-p IMAGE="web-server-mylly" \
-p IMAGE_PROJECT=$backend_project \
-p SUBPROJECT="" \
-p SUBPROJECT_POSTFIX="" \
  | jq '.items[0].spec.template.spec.containers[0].ports[0].containerPort=8000' \
  | jq '.items[0].spec.template.spec.containers[0].ports[0].name="api"' \
  | jq '.items[0].spec.template.spec.containers[0].ports[0].protocol="TCP"' \
  | jq '.items[0].spec.template.spec.containers[1].ports[0].containerPort=8100' \
  | jq '.items[0].spec.template.spec.containers[1].ports[0].name="admin"' \
  | jq '.items[0].spec.template.spec.containers[1].ports[0].protocol="TCP"' \
  | jq '.items[0].spec.template.spec.containers[0].volumeMounts[2].mountPath="/opt/chipster/web-root/assets/conf"' \
  | jq '.items[0].spec.template.spec.containers[0].volumeMounts[2].name="app-conf"' \
  | jq '.items[0].spec.template.spec.volumes[2].name="app-conf"' \
  | jq '.items[0].spec.template.spec.volumes[2].secret.secretName="web-server-mylly-app"' \
  | oc apply -f -

echo "update service"
oc process -f templates/java-server/java-server-api-service.yaml --local \
-p NAME="web-server-mylly" \
-p PROJECT=$PROJECT \
-p DOMAIN=$DOMAIN \
-p SUBPROJECT="" \
-p SUBPROJECT_POSTFIX="" \
| oc apply -f -

if [ -n "$ip_whitelist_api" ]; then
	ip_whitelist_api_label='.items[0].metadata.annotations."haproxy.router.openshift.io/ip_whitelist"="'$ip_whitelist'"'
else
	ip_whitelist_api_label="."
	echo "no firewall configured for route $PROJECT.$DOMAIN"
fi

if [ -n "$ip_whitelist_admin" ]; then
	ip_whitelist_admin_label='.items[1].metadata.annotations."haproxy.router.openshift.io/ip_whitelist"="'$ip_whitelist_admin'"'
else
	ip_whitelist_admin_label="."
	echo "no firewall configured for route web-server-admin-$PROJECT.$DOMAIN"
fi

if oc get route web-server > /dev/null 2>&1; then
  echo "Warning: cannot have two default routes in the same project, deleting the route web-server"
  oc delete route web-server
fi

echo "update route"
oc process -f templates/java-server/java-server-api-route.yaml --local \
-p NAME="web-server-mylly" \
-p PROJECT=$PROJECT \
-p DOMAIN=$DOMAIN \
-p SUBPROJECT="" \
-p SUBPROJECT_POSTFIX="" \
| jq '.items[0].spec.host="'$PROJECT.$DOMAIN'"' \
| jq "$ip_whitelist_api_label" \
| oc apply -f -
    

echo "update admin service and route"
oc process -f templates/java-server/java-server-admin.yaml --local \
-p NAME="web-server-mylly" \
-p PROJECT=$PROJECT \
-p DOMAIN=$DOMAIN \
-p SUBPROJECT="" \
-p SUBPROJECT_POSTFIX="" \
| jq "$ip_whitelist_admin_label" \
| oc apply -f -

echo "copy monitoring secret"

# copy the monitoring secret if this is not the backend project
if [[ $backend_project != "$PROJECT" ]]; then
	if oc get secret monitoring > /dev/null 2>&1; then
		oc delete secret monitoring
	fi
	oc get secret monitoring -n $backend_project -o json \
	| jq '.metadata.namespace="'$PROJECT'"' \
	| oc apply -f -
fi

service_locator_uri="$(curl -s https://service-locator-${backend}/services?pretty | grep service-locator | grep publicUri | cut -d '"' -f 4)"
secret_web_server_yaml="$(oc get secret web-server -n $backend_project -o json | jq '.data["chipster.yaml"]' -r | base64 --decode | yq w - url-int-service-locator $service_locator_uri)"

secret_web_server_yaml="$(echo "$secret_web_server_yaml" | yq w - url-int-service-locator $service_locator_uri)"

# use external addresses if this is a different project
if [[ $backend_project != "$PROJECT" ]]; then
  secret_web_server_yaml="$(echo "$secret_web_server_yaml" | yq w - use-external-addresses true)"
fi

secret_web_server="$(echo "$secret_web_server_yaml" | base64)"

if oc get secret web-server-mylly > /dev/null 2>&1; then
  oc delete secret web-server-mylly
fi

echo "create web-server-mylly secret"
oc get secret web-server -n $backend_project -o json \
| jq '.metadata.namespace="'$PROJECT'"' \
| jq '.metadata.name="web-server-mylly"' \
| jq ".data[\"chipster.yaml\"]=\"$secret_web_server\"" \
| oc apply -f -

chipster_app="$(oc get secret web-server-app -n $backend_project -o json | jq ".data[\"chipster.yaml\"]" -r | base64 --decode)"
mylly_app="$(cat mylly-conf/web-server-app-conf/chipster.yaml)"
secret_web_server_app="$(yq merge <(echo "$mylly_app") <(echo "$chipster_app") | base64)"

if oc get secret web-server-mylly-app > /dev/null 2>&1; then
  oc delete secret web-server-mylly-app
fi

echo "create web-server-mylly-app secret"
oc get secret web-server-app -n $backend_project -o json \
| jq '.metadata.namespace="'$PROJECT'"' \
| jq '.metadata.name="web-server-mylly-app"' \
| jq ".data[\"chipster.yaml\"]=\"$secret_web_server_app\"" \
| oc apply -f -	
