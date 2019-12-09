set -e

# make images web-server-mylly and monitoring "shared" in Rahti registry

backend="$1"

if [ -z $backend ]; then
	echo "Usage:     bash deploy-mylly-app.bash BACKEND"
	echo "  Example: bash deploy-mylly-app.bash chipster.rahtiapp.fi"
	exit 1
fi

oc project mylly

source scripts/utils.bash

# "oc apply" refuses change the existing objects, because object version in the chipster project is different
delete_list=(
	dc/web-server
	secret/monitoring
	secret/web-server
	route/web-server
	service/web-server
	secret/web-server-app
)

echo "delete old objects"
for obj in ${delete_list[*]}; do
	if oc get $obj > /dev/null 2>&1; then
	  oc delete $obj
	fi
done

oc get dc web-server -n chipster -o json \
  | jq '.metadata.namespace="mylly"' \
  | jq '.spec.template.spec.containers[0].image="docker-registry.default.svc:5000/'$PROJECT'/web-server-mylly"' \
  | jq '.spec.triggers[1].imageChangeParams.from.name="web-server-mylly:latest"' \
  | oc apply -f -

oc get secret monitoring -n chipster -o json | jq '.metadata.namespace="mylly"' | oc apply -f -

service_locator_uri="$(curl -s https://service-locator-${backend}/services?pretty | grep service-locator | grep publicUri | cut -d '"' -f 4)"
secret_web_server="$(oc get secret web-server -n chipster -o json | jq '.data["chipster.yaml"]' -r | base64 --decode | yq w - url-int-service-locator $service_locator_uri | base64)"

oc get secret web-server -n chipster -o json \
| jq '.metadata.namespace="mylly"' \
| jq ".data[\"chipster.yaml\"]=\"$secret_web_server\"" \
| oc apply -f -
	
oc get route web-server -n chipster -o json \
| jq '.metadata.namespace="mylly"' \
| jq ".spec.host=\"mylly.$DOMAIN\"" \
| oc apply -f -

oc get service web-server -n chipster -o json \
| jq '.metadata.namespace="mylly"' \
| jq '.spec.clusterIP=""' \
| oc apply -f -

chipster_app="$(oc get secret web-server-app -n chipster -o json | jq ".data[\"chipster.yaml\"]" -r | base64 --decode)"
mylly_app="$(cat mylly-conf/web-server-app-conf/chipster.yaml)"
secret_web_server_app="$(yq merge <(echo "$mylly_app") <(echo "$chipster_app") | base64)"

oc get secret web-server-app -n chipster -o json \
| jq '.metadata.namespace="mylly"' \
| jq ".data[\"chipster.yaml\"]=\"$secret_web_server_app\"" \
| oc apply -f -	
