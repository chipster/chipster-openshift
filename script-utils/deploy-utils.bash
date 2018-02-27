#!/bin/bash

# parse the current project name
function get_project {
  oc project -q
}

# parse the current project domain (i.e. the address of this OpenShift)
function get_domain {
  #oc status | grep "In project" | cut -d " " -f 6 | cut -d / -f 3 | cut -d : -f 1
  echo "rahti-int-app.csc.fi"
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
  ext_admin=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-admin-ext-$service:) || true
  int_m2m=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-m2m-int-$service:) || true
  port=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-bind-$service: | cut -d : -f 4) || true
  port_admin=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-admin-bind-$service: | cut -d : -f 4) || true
  port_m2m=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-m2m-bind-$service: | cut -d : -f 4) || true
  
  # if the service has internal or external address, we have to expose it's port
  if [ -n "$internal" ] || [ -n "$external" ]; then
    echo "Create service $service $port"
  	oc expose dc $service --port=$port
  	
  	# HTTPS
  	echo "Create route"
  	if [ $service != "web-server" ]; then 
  	  if [ -n "$external" ]; then
	  	oc create route edge --service $service --port $port --insecure-policy=Redirect 
  	  fi
    fi
  fi
  
  if [ -n "$ext_admin" ]; then
    echo "Create admin service $service $port"
  	oc expose dc $service --port=$port_admin --name $service-admin
  	# HTTPS
  	echo "Create route"
  	oc create route edge --service $service-admin --port $port_admin --insecure-policy=Redirect
  	echo "Create IP whitelist"
  	oc annotate route $service-admin "$(cat ../chipster-private/confs/rahti-int/admin-route-annotations)" --overwrite
  fi
  
  if [ -n "$int_m2m" ]; then
    echo "Create m2m service $service $port_m2m"
  	oc expose dc $service --port=$port_m2m --name $service-m2m  	
  fi 
}

# configure a service to path /opt/chipster/$service/
function configure_service2 {
  service=$1

  retry oc set volume dc/$service --add -t emptyDir --mount-path /opt/chipster/$service/logs  	
  retry	oc set volume dc/$service --add -t secret --secret-name ${service}-conf --mount-path /opt/chipster/$service/conf/
  
  internal=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-int-$service:) || true
  external=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-ext-$service:) || true
  ext_admin=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-admin-ext-$service:) || true
  port=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-bind-$service: | cut -d : -f 4) || true
  port_admin=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-admin-bind-$service: | cut -d : -f 4) || true
  
  # if the service has internal or external address, we have to expose it's port
  if [ -n "$internal" ] || [ -n "$external" ]; then
  	oc expose dc $service --port=$port
  	
  	if [ $service != "web-server" ]; then 
  	  if [ -n "$external" ]; then
	  	oc create route edge --service $service --port $port --insecure-policy=Redirect 
  	  fi
    fi
  fi
  
  if [ -n "$ext_admin" ]; then
    echo "Create admin service $service $port"
  	oc expose dc $service --port=$port_admin --name $service-admin
  	# HTTPS
  	echo "Create route"
  	oc create route edge --service $service-admin --port $port_admin --insecure-policy=Redirect
  	echo "Create IP whitelist"
  	oc annotate route $service-admin "$(cat ../chipster-private/confs/rahti-int/admin-route-annotations)" --overwrite
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
	pvc_name=$2
	size=$3
	mount_path=$4
	access_mode=$5
	
	dc_volume_name=$pvc_name-volume
	
	# oc delete pvc $pvc_name
	
	if ! [[ $(oc get pvc $pvc_name 2> /dev/null) ]]; then
	  # create pvc
	  echo "
apiVersion: \"v1\"
kind: \"PersistentVolumeClaim\"
metadata:
  name: \"$pvc_name\"
spec:
  accessModes:
    - \"$access_mode\"
  resources:
    requests:
      storage: \"$size\"" | oc create -f -
    fi
    
	# oc set volume dc/$service --remove --name $dc_volume_name 
    oc set volume dc/$service --add --claim-name $pvc_name --mount-path $mount_path --name $dc_volume_name
}

function update_dockerfile {
	build_name=$1	
	oc get bc $build_name -o json | jq .spec.source.dockerfile="$(cat  dockerfiles/$build_name/Dockerfile | jq -s -R .)" | oc replace bc $build_name -f -	
}
