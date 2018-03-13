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

function get_image {
  build_name="$1"
  echo docker-registry.default.svc:5000/$PROJECT/$build_name
}

function configure_java_service {
  service=$1
  java_class=$2  
  image="$(get_image chipster-web-server)"
  work_dir="/opt/chipster-web-server"
  configure_service "$service" "$image" "$work_dir" "$java_class"
}


# configure a service to path /opt/chipster-web-server
function configure_service {
  service=$1
  image=$2
  work_dir=$3
  java_class=$4

  internal=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-int-$service:) || true
  external=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-ext-$service:) || true
  ext_admin=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-admin-ext-$service:) || true
  port=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-bind-$service: | cut -d : -f 4) || true
  port_admin=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep url-admin-bind-$service: | cut -d : -f 4) || true

  view="{
      \"service\": \"$service\", 
      \"api-port\": \"$port\", 
      \"admin-port\": \"$port_admin\",
      \"java-class\": \"$java_class\",
      \"project\": \"$PROJECT\",
      \"image\": \"$image\",
      \"work-dir\": \"$work_dir\",
      \"admin-ip-whitelist\": \"$(cat ../chipster-private/confs/rahti-int/admin-ip-whitelist)\"
      }" # no comma after the last line!

  #echo "$view"

  echo "$view" | mustache - deployments/templates/service.yaml > generated/deployments/$service.yaml

  if [ -n "$internal" ] || [ -n "$external" ]; then
    echo "$view" | mustache - services/templates/api.yaml > generated/services/$service.yaml
  	
  	if [ $service != "web-server" ]; then 
  	  if [ -n "$external" ]; then
        echo "$view" | mustache - routes/templates/api.yaml > generated/routes/$service.yaml
  	  fi
    fi
  fi
  
  if [ -n "$ext_admin" ]; then
    echo "$view" | mustache - services/templates/admin.yaml > generated/services/$service-admin.yaml
    echo "$view" | mustache - routes/templates/admin.yaml > generated/routes/$service-admin.yaml
  fi
}

# clean up and create dirs for the generated configs
rm -rf generated/
mkdir -p generated/deployments
mkdir -p generated/services
mkdir -p generated/routes

# copy all fixed configs
cp deployments/*.yaml generated/deployments
cp services/*.yaml generated/services
cp routes/*.yaml generated/routes

# service specific template(s)
view="{
      \"project\": \"$PROJECT\",
      \"app-domain\": \"$DOMAIN\",
      \"admin-ip-whitelist\": \"$(cat ../chipster-private/confs/rahti-int/admin-ip-whitelist)\"
      }"

echo "$view" | mustache - routes/templates/web-server.yaml > generated/routes/web-server.yaml &

# shared templates and shared image
configure_java_service auth fi.csc.chipster.auth.AuthenticationService &
configure_java_service service-locator fi.csc.chipster.servicelocator.ServiceLocator &
configure_java_service session-db fi.csc.chipster.sessiondb.SessionDb &
configure_java_service file-broker fi.csc.chipster.filebroker.FileBroker &
configure_java_service scheduler fi.csc.chipster.scheduler.Scheduler &
configure_java_service session-worker fi.csc.chipster.sessionworker.SessionWorker &

# shared templates and custom image 
configure_service toolbox "$(get_image toolbox)" /opt/chipster-web-server &
configure_service type-service "$(get_image chipster-web-server-js)" /opt/chipster-web-server &
configure_service web-server "$(get_image web-server)" /opt/chipster-web-server &
configure_service comp "$(get_image comp)" /opt/chipster/comp &

wait
