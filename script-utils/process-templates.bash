#!/bin/bash

set -e

echo project: $PROJECT domain: $DOMAIN

max_pods=$(oc get quota -o json | jq .items[].spec.hard.pods -r | grep -v null)
max_storage=$(oc get quota -o json | jq .items[].spec.hard.\"requests.storage\" -r | grep -v null | sed s/Gi// | sed s/Ti/000/)
max_ram=$(oc get limits -o json | jq .items[].spec.limits[].max.memory -r | sed s/Gi//g | sort -n | head -n 1)
max_cores=$(oc get limits -o json | jq .items[].spec.limits[].max.cpu -r | sort -n | head -n 1)

function configure_java_service {
  service=$1
  java_class=$2  
  image="chipster-web-server"
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

  echo "$view" | mustache - templates/deploymentconfigs/shared/service.yaml > processed-templates/deploymentconfigs/$service.yaml

  if [ -n "$internal" ] || [ -n "$external" ]; then
    echo "$view" | mustache - templates/services/shared/api.yaml > processed-templates/services/$service.yaml
  	
  	if [ $service != "web-server" ]; then 
  	  if [ -n "$external" ]; then
        echo "$view" | mustache - templates/routes/shared/api.yaml > processed-templates/routes/$service.yaml
  	  fi
    fi
  fi
  
  if [ -n "$ext_admin" ]; then
    echo "$view" | mustache - templates/services/shared/admin.yaml > processed-templates/services/$service-admin.yaml
    echo "$view" | mustache - templates/routes/shared/admin.yaml > processed-templates/routes/$service-admin.yaml
  fi
}

# clean up

# clean up and create dirs for the generated configs
rm -rf processed-templates/
mkdir -p processed-templates/deploymentconfigs/patches
mkdir -p processed-templates/services
mkdir -p processed-templates/routes
mkdir -p processed-templates/pvcs


# fixed size for tools-bin if there is enough quota
if [ $max_storage -gt 900 ]; then
  tools_size="500"
else
  tools_size="5"
fi

if [ $max_storage -gt 900 ]; then
  file_broker_storage_size="$(echo '(' $max_storage ' - 500) * 0.75 / 1' | bc)"
else
  file_broker_storage_size="10"
fi 

# don't start optional services if the pod quota is low
if [ $max_pods -gt 25 ]; then
  optional_replicas="1"
else
  optional_replicas="0"
fi

# leave some for the monitoring container
comp_ram=$(echo $max_ram '* 1000 - 100' | bc )
comp_cores=$(echo $max_cores '* 1000 - 100' | bc )

# service specific templates

view="{
      \"project\": \"$PROJECT\",
      \"app-domain\": \"$DOMAIN\",
      \"comp-data-size\": \"$(echo $max_storage '* 0.05 / 1' | bc)\",
      \"file-broker-storage-size\": \"$file_broker_storage_size\",
      \"tools-size\": \"$tools_size\",
      \"optional-replicas\": \"$optional_replicas\",
      \"comp-ram\": \"$comp_ram\",
      \"comp-cores\": \"$comp_cores\",
      \"admin-ip-whitelist\": \"$(cat ../chipster-private/confs/rahti-int/admin-ip-whitelist)\"
      }"

#echo "$view"

for f in templates/deploymentconfigs/*.yaml; do
  name=$(basename $f .yaml)
  echo "$view" | mustache - $f > processed-templates/deploymentconfigs/$name.yaml &
done

# patches don't use the variables yet but let's process them anyway because of consistency
for f in templates/deploymentconfigs/patches/*.yaml; do
  name=$(basename $f .yaml)
  echo "$view" | mustache - $f > processed-templates/deploymentconfigs/patches/$name.yaml &
done

for f in templates/services/*.yaml; do
  name=$(basename $f .yaml)
  echo "$view" | mustache - $f > processed-templates/services/$name.yaml &
done

for f in templates/routes/*.yaml; do
  name=$(basename $f .yaml)
  echo "$view" | mustache - $f > processed-templates/routes/$name.yaml &
done

for f in templates/pvcs/*.yaml; do
  name=$(basename $f .yaml)
  echo "$view" | mustache - $f > processed-templates/pvcs/$name.yaml &
done

wait

# shared templates and shared image

configure_java_service auth fi.csc.chipster.auth.AuthenticationService &
configure_java_service service-locator fi.csc.chipster.servicelocator.ServiceLocator &
configure_java_service session-db fi.csc.chipster.sessiondb.SessionDb &
configure_java_service file-broker fi.csc.chipster.filebroker.FileBroker &
configure_java_service scheduler fi.csc.chipster.scheduler.Scheduler &
configure_java_service session-worker fi.csc.chipster.sessionworker.SessionWorker &
configure_java_service job-history fi.csc.chipster.jobhistory.JobHistoryService &

# shared templates and custom image 

configure_service toolbox toolbox /opt/chipster-web-server &
configure_service type-service chipster-web-server-js /opt/chipster-web-server &
configure_service web-server web-server /opt/chipster-web-server &
configure_service comp comp /opt/chipster/comp &

wait
