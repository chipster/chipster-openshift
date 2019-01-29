#!/bin/bash

set -e

source scripts/utils.bash

# add the ip whitelist annotation to all routes in the given template
function apply_firewall {
  processed_template="$1"
  ip_whitelist_path="$2"
  
  for i in $(seq 0 $(jq '.items | length' $processed_template)); do
    kind=$(yq r $processed_template items[$i].kind)
    if [ "$kind" = "Route" ]; then
  	  yq w -i $processed_template items[$i].metadata.annotations.\"haproxy.router.openshift.io/ip_whitelist\" "$(cat $ip_whitelist_path)"
  	fi
  done
}

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

  internal=$(cat $chipster_defaults_path | grep url-int-$service:) || true
  external=$(cat $chipster_defaults_path | grep url-ext-$service:) || true
  ext_admin=$(cat $chipster_defaults_path | grep url-admin-ext-$service:) || true
  port=$(cat $chipster_defaults_path | grep url-bind-$service: | cut -d : -f 4) || true
  port_admin=$(cat $chipster_defaults_path | grep url-admin-bind-$service: | cut -d : -f 4) || true

  temp_file_path="tmp/$service.yaml"
  
  oc process -f templates/java-server/java-server-dc.yaml --local \
  -p NAME=$service \
  -p API_PORT=$port \
  -p ADMIN_PORT=$port_admin \
  -p JAVA_CLASS=$java_class \
  -p PROJECT=$PROJECT \
  -p IMAGE=$image \
  > $temp_file_path
  
  
  # configure ports for services that have them
  admin_port_index=0

  if [ -n "$port" ]; then
    admin_port_index=1
    echo "
      items[0].spec.template.spec.containers[0].ports[0].containerPort: $port
      items[0].spec.template.spec.containers[0].ports[0].name: api
      items[0].spec.template.spec.containers[0].ports[0].protocol: TCP
      " | yq w -i $temp_file_path --script -
  fi    
  
  if [ -n "$port_admin" ]; then
    echo "
      items[0].spec.template.spec.containers[0].ports[$admin_port_index].containerPort: $port_admin
      items[0].spec.template.spec.containers[0].ports[$admin_port_index].name: admin
      items[0].spec.template.spec.containers[0].ports[$admin_port_index].protocol: TCP
      " | yq w -i $temp_file_path --script -
  fi
  
  cat $temp_file_path >> $template_dir/$service.yaml
  
  if [ -n "$internal" ] || [ -n "$external" ]; then
    # create OpenShift service
    oc process -f templates/java-server/java-server-api.yaml --local \
    -p NAME=$service \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    > $temp_file_path
        
    if [ -f $ip_whitelist_api_path ]; then
      apply_firewall $temp_file_path $ip_whitelist_api_path
    fi
    
    cat $temp_file_path >> $template_dir/$service_api.yaml
  fi
  
  # create route if necessary
  if [ -n "$ext_admin" ]; then
    # create route
    oc process -f templates/java-server/java-server-admin.yaml --local \
    -p NAME=$service \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    > $temp_file_path
    
    if [ -f $ip_whitelist_admin_path ]; then
      apply_firewall $temp_file_path $ip_whitelist_admin_path
    fi
    
    cat $temp_file_path >> $template_dir/$service_admin.yaml
  fi
  
  rm -f $temp_file_path
}


if [[ $(oc get dc) ]] || [[ $(oc get service -o name | grep -v glusterfs-dynamic-) ]] || [[ $(oc get routes) ]] ; then
  echo "The project is not empty"
  echo ""
  echo "The scirpt will continue, but it won't delete any extra deployments you possibly have."
  echo "Run the following command to remove all deployments:"
  echo ""
  echo "    bash delete-all-services.bash"
  echo ""
  echo "and if your want to remove volumes too:"
  echo ""
  echo "    oc delete pvc --all"
  echo ""
fi

PROJECT=$(oc project -q)
DOMAIN=$(get_domain)

echo project: $PROJECT domain: $DOMAIN

max_pods=$(oc get quota -o json | jq .items[].spec.hard.pods -r | grep -v null)
max_storage=$(oc get quota -o json | jq .items[].spec.hard.\"requests.storage\" -r | grep -v null | sed s/Gi// | sed s/Ti/000/)

chipster_defaults_path="../../chipster-web-server/src/main/resources/chipster-defaults.yaml"
mylly=false

ip_whitelist_api_path="../../chipster-private/confs/rahti-int/admin-ip-whitelist"
ip_whitelist_admin_path="../../chipster-private/confs/rahti-int/admin-ip-whitelist"

template_dir="tmp/chipster_template_parts"

mkdir -p $template_dir
rm -f $template_dir/*

# shared templates and shared image

echo "generate server templates"

configure_java_service auth fi.csc.chipster.auth.AuthenticationService
configure_java_service service-locator fi.csc.chipster.servicelocator.ServiceLocator
configure_java_service session-db fi.csc.chipster.sessiondb.SessionDb
configure_java_service file-broker fi.csc.chipster.filebroker.FileBroker
configure_java_service scheduler fi.csc.chipster.scheduler.Scheduler
configure_java_service session-worker fi.csc.chipster.sessionworker.SessionWorker
configure_java_service backup fi.csc.chipster.backup.Backup
configure_java_service job-history fi.csc.chipster.jobhistory.JobHistoryService

# shared templates and custom image 

configure_service toolbox toolbox /opt/chipster-web-server
configure_service type-service chipster-web-server-js /opt/chipster-web-server
configure_service web-server web-server /opt/chipster-web-server
configure_service comp comp /opt/chipster/comp

if [ "$mylly" = true ]; then
  # create mylly config by replacing almost all ocurrances of comp to comp-mylly, except the paths
  # TODO use yq or jq instead of sed
  
  # delete the old dc, otherwise updates fail as the comp version won't match with the old comp-mylly version
  if oc get dc/comp-mylly > /dev/null 2>&1 ; then
    oc delete dc/comp-mylly
  fi
  
  oc get dc/comp -o yaml \
	| sed s/comp/comp-mylly/g \
	| sed s_/opt/chipster/comp-mylly_/opt/chipster/comp_g \
	| yq r - items >> $chipster_template
fi

oc process -f templates/custom-objects.yaml --local \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    >> $template_dir/custom-objects.yaml

oc process -f templates/pvcs.yaml --local >> $template_dir/pvcs.yaml

temp_file="tmp/monitoring.yaml"
oc process -f templates/monitoring.yaml --local \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    > $temp_file
    
    apply_firewall $temp_file $ip_whitelist_admin_path
    cat $temp_file >> $template_dir/monitoring.yaml
        
rm $temp_file

template="tmp/chipster_template.yaml"
yq merge --append $template_dir/*.yaml > $template 

scriptPath="../../chipster-private/confs/$PROJECT.$DOMAIN/chipster-template-patch.bash"

if [ -f $scriptPath ]; then
  echo "apply project specific customizations in $scriptPath"
  bash $scriptPath $template
fi

echo "apply the template to the server"
oc apply -f $template
rm $template
rm -f $template_dir/*
    
echo "patch servers"
for f in templates/java-server/patches/*.yaml; do
  name=$(basename $f .yaml)
  oc patch dc $name -p "$(cat $f)"
done

if [ "$max_pods" -lt 40 ]; then
  echo "disabled non-critical services because of low pod quota"
  oc get dc/backup      -o yaml | yq w - spec.replicas 0 | oc apply -f -
  oc get dc/job-history -o yaml | yq w - spec.replicas 0 | oc apply -f -
  oc get dc/influx      -o yaml | yq w - spec.replicas 0 | oc apply -f -
  oc get dc/grafana     -o yaml | yq w - spec.replicas 0 | oc apply -f -
fi
