#!/bin/bash

set -e

source scripts/utils.bash

# add the ip whitelist annotation to all routes in the given template
function apply_firewall {
  file="$1"
  ip_whitelist="$2"
  	
  patch_kind $file Route \
  	"metadata.annotations.\"haproxy.router.openshift.io/ip_whitelist\": $ip_whitelist"
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
  
  oc process -f templates/java-server/java-server-dc.yaml --local \
  -p NAME=$service \
  -p API_PORT=$port \
  -p ADMIN_PORT=$port_admin \
  -p JAVA_CLASS=$java_class \
  -p PROJECT=$PROJECT \
  -p IMAGE=$image \
  -p IMAGE_PROJECT=$image_project \
  > $template_dir/$service-dc.yaml
  
  # configure ports for services that have them
  admin_port_index=0

  if [ -n "$port" ]; then
  	
    admin_port_index=1
    patch_kind_and_name $template_dir/$service-dc.yaml DeploymentConfig $service "
      spec.template.spec.containers[0].ports[0].containerPort: $port
      spec.template.spec.containers[0].ports[0].name: api
      spec.template.spec.containers[0].ports[0].protocol: TCP
    " false
  fi
  
  if [ -n "$port_admin" ]; then
  
    patch_kind_and_name $template_dir/$service-dc.yaml DeploymentConfig $service "
      spec.template.spec.containers[0].ports[$admin_port_index].containerPort: $port_admin
      spec.template.spec.containers[0].ports[$admin_port_index].name: admin
      spec.template.spec.containers[0].ports[$admin_port_index].protocol: TCP
    " false
  fi
  
  if [ -n "$internal" ] || [ -n "$external" ]; then
    # create OpenShift service
    oc process -f templates/java-server/java-server-api.yaml --local \
    -p NAME=$service \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    > $template_dir/$service-api.yaml
        
    ip_whitelist="$(get_deploy_config ip-whitelist-api)"
    
    if [ -n "$ip_whitelist" ]; then
      apply_firewall $template_dir/$service-api.yaml "$ip_whitelist"
    else
      echo "no firewall configured for route $service"  
    fi
  fi
  
  # create route if necessary
  if [ -n "$ext_admin" ]; then
    # create route
    oc process -f templates/java-server/java-server-admin.yaml --local \
    -p NAME=$service \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    > $template_dir/$service-admin.yaml
    
    ip_whitelist="$(get_deploy_config ip-whitelist-admin)"
    if [ -n "$ip_whitelist" ]; then
      apply_firewall $template_dir/$service-admin.yaml "$ip_whitelist"
    else
      echo "no firewall configured for route $service-admin" 
    fi
  fi
}

function get_deploy_config {

  key="$1"

  deploy_config_path_shared="../chipster-private/confs/chipster-all/deploy.yaml"
  deploy_config_path_project="../chipster-private/confs/$PROJECT.$DOMAIN/deploy.yaml"

  # if project specific file exists
  if [ -f $deploy_config_path_project ]; then
    value="$(yq r $deploy_config_path_project "$key")"
    # if the key was found    
    if [ "$value" != "null" ]; then
      echo "$value"
      return
    fi
  fi
  
  # not found from project specific, try shared
  if [ -f $deploy_config_path_shared ]; then
    value="$(yq r $deploy_config_path_shared "$key")"
    if [ "$value" != "null" ]; then
      echo "$value"
      return
    fi
  fi
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

chipster_defaults_path="../chipster-web-server/src/main/resources/chipster-defaults.yaml"
mylly=false

image_project="chipster-jenkins"

template_dir="tmp/chipster_template_parts"

mkdir -p $template_dir
rm -f $template_dir/*

# shared templates and shared image

echo "generate server templates"

configure_java_service auth fi.csc.chipster.auth.AuthenticationService &
configure_java_service service-locator fi.csc.chipster.servicelocator.ServiceLocator &
configure_java_service session-db fi.csc.chipster.sessiondb.SessionDb &
configure_java_service file-broker fi.csc.chipster.filebroker.FileBroker &
configure_java_service scheduler fi.csc.chipster.scheduler.Scheduler &
configure_java_service session-worker fi.csc.chipster.sessionworker.SessionWorker &
configure_java_service backup fi.csc.chipster.backup.Backup &
configure_java_service job-history fi.csc.chipster.jobhistory.JobHistoryService &

# shared templates and custom image 

configure_service toolbox toolbox /opt/chipster-web-server &
configure_service type-service chipster-web-server-js /opt/chipster-web-server &
configure_service web-server web-server /opt/chipster-web-server &
configure_service comp comp /opt/chipster/comp &

wait

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
    > $template_dir/custom-objects.yaml

oc process -f templates/pvcs.yaml --local > $template_dir/pvcs.yaml

oc process -f templates/monitoring.yaml --local \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    > $template_dir/monitoring.yaml
    
    apply_firewall $template_dir/monitoring.yaml $ip_whitelist_admin_path

# it would be cleaner to patch after the merge, but patching the large file takes about 20 seconds, when
# patching these small files takes less than a second
echo "customize individual servers"
bash templates/java-server/patch.bash $template_dir $PROJECT $DOMAIN

max_pods=$(oc get quota -o json | jq .items[].spec.hard.pods -r | grep -v null)

if [ "$max_pods" -lt 40 ]; then
  echo "disabled non-critical services because of low pod quota"
  bash templates/patch-low-pod-quota.bash $template_dir
fi
 
template="tmp/chipster_template.yaml"
yq merge --append $template_dir/*.yaml > $template

scriptPath="../chipster-private/confs/$PROJECT.$DOMAIN/chipster-template-patch.bash"

if [ -f $scriptPath ]; then
  echo "apply project specific customizations in $scriptPath"
  bash $scriptPath $template
fi

echo "apply the template to the server"
oc apply -f $template | tee tmp/apply.out | grep -v unchanged
echo $(cat tmp/apply.out | grep unchanged | wc -l) unchanged 
rm tmp/apply.out

rm $template
rm -f $template_dir/*
