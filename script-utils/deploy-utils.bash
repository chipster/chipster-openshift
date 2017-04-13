#!/bin/bash

function get_project {
  oc project -q
}

function get_domain {
  oc status | grep "In project" | cut -d " " -f 6 | cut -d / -f 3 | cut -d : -f 1
}

PROJECT=$(get_project)
DOMAIN=$(get_domain)

function retry {
  for i in {1..5}; do
    $@ && break
    sleep 1
  done	
}

# deploy

function delete_service {
  service=$1
  
  if [[ $(oc get route $service 2> /dev/null) ]]; then
  	oc delete route $service  
  fi
  
  if [[ $(oc get service $service 2> /dev/null) ]]; then
  	oc delete service $service  
  fi
  
  if [[ $(oc get dc $service 2> /dev/null) ]]; then
  	oc delete dc $service  
  fi
}

function configure_service {
  service=$1

  retry oc set volume dc/$service --add -t emptyDir --mount-path /opt/chipster-web-server/logs  	
  retry	oc set volume dc/$service --add -t secret --secret-name ${service}-conf --mount-path /opt/chipster-web-server/conf/
  
  internal=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-int-$service:) || true
  external=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-ext-$service:) || true
  port=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-bind-$service: | cut -d : -f 4) || true
  
  # if the service has internal or external address, we have to expose it's port
  if [ -n "$internal" ] || [ -n "$external" ]; then
  	oc expose dc $service --port=$port
  fi
  
  if [ $service != "web-server" ]; then 
  	if [ -n "$external" ]; then
  		oc expose service $service
  	fi
  fi
}

function deploy_service {

  service=$1

  delete_service $service
  
  oc new-app $service
  
  configure_service $service
}

function deploy_js_service {
  service=$1
  
  delete_service $service
  
  oc new-app chipster-web-server-js -e JS_FILE=$service.js --name $service
  
  configure_service $service
}

function deploy_java_service {
  service=$1
  class=$2
  
  delete_service $service
  
  oc new-app chipster-web-server -e JAVA_CLASS=$class --name $service
  
  configure_service $service
}

function add_volume {
	service=$1
	volume_name=$2
	size=$3
	
	if [[ $(oc get pvc $service-$volume_name 2> /dev/null) ]]; then
  	  oc delete pvc $service-$volume_name
    fi

	retry oc set volume dc/$service --add --name $service-$volume_name -t pvc --mount-path /opt/chipster-web-server/$volume_name --claim-name=$service-$volume_name --claim-size=$size --overwrite
}
