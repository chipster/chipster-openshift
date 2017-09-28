#!/bin/bash

# parse the current project name
function get_project {
  oc project -q
}

# parse the current project domain (i.e. the address of this OpenShift)
function get_domain {
  oc status | grep "In project" | cut -d " " -f 6 | cut -d / -f 3 | cut -d : -f 1
}

PROJECT=$(get_project)
DOMAIN=$(get_domain)

# retry the command for max five times or until it's exit value is zero 
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

# configure a service to path /opt/chipster-web-server
function configure_service {
  service=$1

  retry oc set volume dc/$service --add -t emptyDir --mount-path /opt/chipster-web-server/logs  	
  retry	oc set volume dc/$service --add -t secret --secret-name ${service}-conf --mount-path /opt/chipster-web-server/conf/
  
  internal=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-int-$service:) || true
  external=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-ext-$service:) || true
  port=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-bind-$service: | cut -d : -f 4) || true
  
  # if the service has internal or external address, we have to expose it's port
  if [ -n "$internal" ] || [ -n "$external" ]; then
  	# HTTP
  	#oc expose dc $service --port=$port
  	# HTTPS
  	oc create route edge --service $service --port $port --insecure-policy=Redirect
  fi
  
  if [ $service != "web-server" ]; then 
  	if [ -n "$external" ]; then
  		oc expose service $service
  	fi
  fi
}

# configure a service to path /opt/chipster/$service/
function configure_service2 {
  service=$1

  retry oc set volume dc/$service --add -t emptyDir --mount-path /opt/chipster/$service/logs  	
  retry	oc set volume dc/$service --add -t secret --secret-name ${service}-conf --mount-path /opt/chipster/$service/conf/
  
  internal=$(cat ../chipster/$service/conf/chipster-defaults.yaml | grep url-int-$service:) || true
  external=$(cat ../chipster/$service/conf/chipster-defaults.yaml | grep url-ext-$service:) || true
  port=$(cat ../chipster/$service/conf/chipster-defaults.yaml | grep url-bind-$service: | cut -d : -f 4) || true
  
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

function deploy_service2 {

  service=$1

  delete_service $service
  
  oc new-app $service
  
  configure_service2 $service
}

function deploy_js_service {
  service=$1
  
  delete_service $service
  
  oc new-app chipster-web-server-js --name $service
  
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
