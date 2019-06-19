oc project mylly
# make images web-server and monitoring "shared" in Rahti registry

oc get dc web-server -n chipster -o json
oc get dc web-server -n chipster -o json | jq '.metadata.namespace="mylly"' | oc apply -f -

oc get secret monitoring -n chipster -o json | jq '.metadata.namespace="mylly"' | oc apply -f -

service_locator_uri="$(curl -s https://service-locator-chipster.rahti-int-app.csc.fi/services?pretty | grep service-locator | grep publicUri | cut -d '"' -f 4)"
secret_web_server="$(oc get secret web-server -n chipster -o json | jq '.data["chipster.yaml"]' -r | base64 --decode | yq w - url-int-service-locator $service_locator_uri | base64)"

oc get secret web-server -n chipster -o json \
| jq '.metadata.namespace="mylly"' \
| jq ".data[\"chipster.yaml\"]=\"$secret_web_server\"" \
| oc apply -f -
	
oc get route web-server -n chipster -o json \
| jq '.metadata.namespace="mylly"' \
| jq ".spec.host=\"mylly.rahti-int-app.csc.fi\"" \
| oc apply -f -

oc get service web-server -n chipster -o json \
| jq '.metadata.namespace="mylly"' \
| jq '.spec.clusterIP=""' \
| oc apply -f -

secret_web_server_app="$(oc get secret web-server-app -n chipster -o json | jq ".data[\"chipster.yaml\"]" -r | base64 --decode \
| yq w - modules [] \
| yq w - modules[0] Kielipankki \
| yq w - manual-path assets/manual/kielipankki/manual/ \
| yq w - manual-tool-postfix .en.src.html \
| yq w - app-name Mylly \
| yq w - app-id mylly \
| yq w - custom-css assets/manual/kielipankki/manual/app-mylly-styles.css \
| yq w - favicon assets/manual/kielipankki/manual/app-mylly-favicon.png \
| yq w - home-path assets/manual/kielipankki/manual/app-home.html \
| yq w - home-header-path assets/manual/kielipankki/manual/app-home-header.html \
| yq w - contact-path assets/manual/kielipankki/manual/app-contact.html \
| yq w - visualization-blacklist '["phenodata"]' \
| yq w - example-session-owner-user-id jaas/mylly_example_session_owner \
| base64)"

oc get secret web-server-app -n chipster -o json \
| jq '.metadata.namespace="mylly"' \
| jq ".data[\"chipster.yaml\"]=\"$secret_web_server_app\"" \
| oc apply -f -	
