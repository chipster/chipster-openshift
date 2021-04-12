#!/bin/bash

set -e
set -o pipefail

source scripts/utils.bash

function vault_view {
  file="$1"

  if [ -z "$VAULT_PASS" ]; then
    echo "enter ansible-vault password for file $file or store it in \$VAULT_PASS" >&2
    ansible-vault view "$file"
  else
    echo "using ansible-vault password for file $file from \$VAULT_PASS" >&2
    ansible-vault view "$file" --vault-password-file <(echo "$VAULT_PASS")
  fi
}

# add the ip whitelist annotation to all routes in the given template
function apply_firewall {
  file="$1"
  ip_whitelist="$2"
  	
  patch_kind $file Route \
  	"metadata.annotations.\"haproxy.router.openshift.io/ip_whitelist\": $ip_whitelist"
}

function configure_java_service {
  subproject_postfix=$1
  service=$2
  java_class=$3  
  image="chipster-web-server"
  role=$service
  configure_service "$subproject_postfix" "$service" "$image" "$role" "$java_class"
}

# configure a service to path /opt/chipster-web-server
function configure_service {
  subproject_postfix=$1
  service=$2
  image=$3
  role=$4
  java_class=$5

  #>&2 echo configure_service "'"$subproject_postfix"'" "'"$service"'" "'"$image"'" "'"$role"'" "'"$java_class"'"
    
  api_port=$(yq r $chipster_defaults_path url-bind-$role | cut -d : -f 3) || true
  admin_port=$(yq r $chipster_defaults_path url-admin-bind-$role | cut -d : -f 3) || true
  
  create_api_service=$(yq r $chipster_defaults_path url-int-$role) || true
  create_api_route=$(yq r $chipster_defaults_path url-ext-$role) || true
  create_admin_service_and_route=$(yq r $chipster_defaults_path url-admin-ext-$role) || true
  
  #echo "$service 	$api_port 	$admin_port 	$create_api_service 	$create_api_route 	$create_admin_service_and_route"
  
  mkdir -p $template_dir/$service
  
  oc process -f templates/java-server/java-server-dc.yaml --local \
  -p NAME=$service \
  -p API_PORT=$api_port \
  -p ADMIN_PORT=$admin_port \
  -p JAVA_CLASS=$java_class \
  -p PROJECT=$PROJECT \
  -p IMAGE=$image \
  -p IMAGE_PROJECT=$image_project \
  -p SUBPROJECT=$subproject \
  -p SUBPROJECT_POSTFIX=$subproject_postfix \
  > $template_dir/$service/dc.yaml
  
  # configure ports for services that have them
  admin_port_index=0

  if [ "$create_api_service" != "null" ]; then
  	
    admin_port_index=1
    patch_kind_and_name $template_dir/$service/dc.yaml DeploymentConfig $service$subproject_postfix "
      spec.template.spec.containers[0].ports[+]: "port-placeholder"
      spec.template.spec.containers[0].ports[0].containerPort: $api_port
      spec.template.spec.containers[0].ports[0].name: api
      spec.template.spec.containers[0].ports[0].protocol: TCP
    " false
    
    # create OpenShift service
    oc process -f templates/java-server/java-server-api-service.yaml --local \
    -p NAME=$service \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    -p SUBPROJECT=$subproject \
    -p SUBPROJECT_POSTFIX=$subproject_postfix \
    > $template_dir/$service/api-service.yaml
  fi
    
  if [ "$create_api_route" != "null" ]; then
  
    # create OpenShift service
    oc process -f templates/java-server/java-server-api-route.yaml --local \
    -p NAME=$service \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    -p SUBPROJECT=$subproject \
    -p SUBPROJECT_POSTFIX=$subproject_postfix \
    > $template_dir/$service/api-route.yaml  
    
    if [ -n "$ip_whitelist_api" ]; then
      apply_firewall $template_dir/$service/api-route.yaml "$ip_whitelist_api"
    else
      echo "no firewall configured for route $service"
    fi
  fi
  
  if [ "$create_admin_service_and_route" != "null" ]; then
  
    patch_kind_and_name $template_dir/$service/dc.yaml DeploymentConfig $service$subproject_postfix "
      spec.template.spec.containers[0].ports[+]: "port-placeholder"
      spec.template.spec.containers[0].ports[$admin_port_index].containerPort: $admin_port
      spec.template.spec.containers[0].ports[$admin_port_index].name: admin
      spec.template.spec.containers[0].ports[$admin_port_index].protocol: TCP
    " false
  
    # create service and route
    oc process -f templates/java-server/java-server-admin.yaml --local \
    -p NAME=$service \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    -p SUBPROJECT=$subproject \
    -p SUBPROJECT_POSTFIX=$subproject_postfix \
    > $template_dir/$service/admin.yaml

    if [ -n "$ip_whitelist_admin" ]; then
      apply_firewall $template_dir/$service/admin.yaml "$ip_whitelist_admin"
    else
      echo "no firewall configured for route $service-admin" 
    fi
  fi
  
  # merge to one file for each service to make it easier to know the right file names for patches 
  yq merge --append $template_dir/$service/*.yaml > $template_dir/$service.yaml
  rm $template_dir/$service/*.yaml
  rmdir $template_dir/$service
}

subproject="$1"
is_debug="$2"

if [ -n "$is_debug" ]; then
  echo enable debug
  set -x
fi

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
  echo subproject: $subproject
fi

PROJECT=$(oc project -q)
DOMAIN=$(get_domain)

echo project: $PROJECT domain: $DOMAIN

private_config_path="../chipster-private/confs"
chipster_defaults_path="../chipster-web-server/src/main/resources/chipster-defaults.yaml"

ip_whitelist_api="$(get_deploy_config $private_config_path ip-whitelist-api $PROJECT $DOMAIN)"
ip_whitelist_admin="$(get_deploy_config $private_config_path ip-whitelist-admin $PROJECT $DOMAIN)"

mylly=$(get_deploy_config $private_config_path mylly $PROJECT $DOMAIN)
if [ -z "$mylly" ]; then  
  mylly=false
fi

only_critical_services=$(get_deploy_config $private_config_path only-critical-services $PROJECT $DOMAIN)
if [ -z "$only_critical_services" ]; then  
  only_critical_services=false
fi

tools_bin=$(get_deploy_config $private_config_path tools-bin $PROJECT $DOMAIN)
if [ -z "$tools_bin" ]; then  
  echo "Tools-bin version is not configured in deploy.yaml"
  echo "- Run 'bash download-tools-bin.bash'"
  echo "- Configure the version in deploy.yaml"
  echo "- Run this script again"
  tools_bin="empty"   
fi

image_project=$(get_image_project $private_config_path $PROJECT $DOMAIN)

# better to do this outside repo
build_dir=$(make_temp chipster-openshift_deploy-builds)
# build_dir="build_temp"
# rm -rf build_temp
# mkdir $build_dir

echo -e "build dir is \033[33;1m$build_dir\033[0m"

template_dir="$build_dir/parts"

rm -rf $build_dir
mkdir -p $template_dir

# shared templates and shared image

echo "generate server templates"

configure_java_service "$subproject_postfix" auth fi.csc.chipster.auth.AuthenticationService
configure_java_service "$subproject_postfix" service-locator fi.csc.chipster.servicelocator.ServiceLocator
configure_java_service "$subproject_postfix" session-db fi.csc.chipster.sessiondb.SessionDb
configure_java_service "$subproject_postfix" file-broker fi.csc.chipster.filebroker.FileBroker
configure_java_service "$subproject_postfix" scheduler fi.csc.chipster.scheduler.Scheduler
configure_java_service "$subproject_postfix" session-worker fi.csc.chipster.sessionworker.SessionWorker
configure_java_service "$subproject_postfix" backup fi.csc.chipster.backup.Backup
configure_java_service "$subproject_postfix" job-history fi.csc.chipster.jobhistory.JobHistoryService


# shared templates and custom image 

configure_service "$subproject_postfix" toolbox toolbox toolbox
configure_service "$subproject_postfix" type-service chipster-web-server-js type-service
configure_service "$subproject_postfix" web-server web-server web-server
configure_service "$subproject_postfix" comp comp comp
configure_service "$subproject_postfix" comp-large comp comp

# configure_service "$subproject_postfix" file-storage-single chipster-web-server file-storage fi.csc.chipster.filestorage.FileStorage &

if [ "$mylly" = true ]; then
  configure_service "$subproject_postfix" comp-mylly comp-mylly comp
else
  echo "skipping mylly"
fi

wait

mkdir -p $template_dir/file-storage
oc process -f templates/file-storage/file-storage.yaml --local \
  -p API_PORT=8016 \
  -p ADMIN_PORT=8116 \
  -p JAVA_CLASS=fi.csc.chipster.filestorage.FileStorage \
  -p PROJECT=$PROJECT \
  -p IMAGE=chipster-web-server \
  -p IMAGE_PROJECT=$image_project \
  -p SUBPROJECT=$subproject \
  -p SUBPROJECT_POSTFIX=$subproject_postfix \
  > $template_dir/file-storage.yaml

oc process -f templates/custom-objects.yaml --local \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    -p SUBPROJECT=$subproject \
    -p SUBPROJECT_POSTFIX=$subproject_postfix \
    > $template_dir/custom-objects.yaml

oc process -f templates/pvcs.yaml --local \
    -p SUBPROJECT=$subproject \
	-p SUBPROJECT_POSTFIX=$subproject_postfix \
	> $template_dir/pvcs.yaml

oc process -f templates/monitoring.yaml --local \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    -p SUBPROJECT=$subproject \
    -p SUBPROJECT_POSTFIX=$subproject_postfix \
    > $template_dir/monitoring.yaml

oc process -f templates/logging.yaml --local \
    -p PROJECT=$PROJECT \
    -p IMAGE_PROJECT=$image_project \
    -p SUBPROJECT=$subproject \
    -p SUBPROJECT_POSTFIX=$subproject_postfix \
    > $template_dir/logging.yaml

# has to be a simple variable assignment to fail on errors
replay_password=$(vault_view ../chipster-private/confs/$PROJECT.$DOMAIN/users | grep replay_test | cut -d ":" -f 2)

oc process -f templates/replay.yaml --local \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    -p SUBPROJECT=$subproject \
    -p SUBPROJECT_POSTFIX=$subproject_postfix \
    -p PASSWORD=$replay_password \
    > $template_dir/replay.yaml

apply_firewall $template_dir/monitoring.yaml "$ip_whitelist_admin"
apply_firewall $template_dir/replay.yaml     "$ip_whitelist_admin"

# it would be cleaner to patch after the merge, but patching the large file takes about 20 seconds, when
# patching these small files takes less than a second
echo "customize individual servers"
bash templates/java-server/patch.bash $template_dir $PROJECT $DOMAIN $tools_bin $subproject 

max_pods=$(oc get quota -o json | jq .items[].spec.hard.pods -r | grep -v null)

if [ "$max_pods" -lt 40 ] || [ "$only_critical_services" = true ]; then
  echo "disable non-critical services because of low pod quota"
  bash templates/patch-low-pod-quota.bash $template_dir $subproject_postfix
  
  oc get dc job-history-postgres$subproject_postfix -o yaml | yq w - spec.replicas 0 | oc apply -f -
else
  oc get dc job-history-postgres$subproject_postfix -o yaml | yq w - spec.replicas 1 | oc apply -f -
fi

sharedScriptPath="$private_config_path/chipster-all/chipster-template-patch.bash"
projectScriptPath="$private_config_path/$PROJECT.$DOMAIN/chipster-template-patch.bash"

if [ -f $sharedScriptPath ]; then
  echo "apply shared customizations in $sharedScriptPath"
  bash $sharedScriptPath $template_dir $subproject_postfix
fi

if [ -f $projectScriptPath ]; then
  echo "apply project specific customizations in $projectScriptPath"
  bash $projectScriptPath $template_dir $subproject_postfix
fi
 

echo "apply the template to the server"

# applying templates one by one (i.e. set do_merge to 0)
# makes it easier to see errors
do_merge=1

if [[ $do_merge == 0 ]]; then 
  for f in $template_dir/*.yaml; do
    echo $f
    oc apply -f $f
  done
else
  template="$build_dir/chipster_template.yaml"

  yq merge --append $template_dir/*.yaml > $template

  apply_out="$build_dir/apply.out"
  oc apply -f $template | tee $apply_out | grep -v unchanged
  echo $(cat $apply_out | grep unchanged | wc -l) objects unchanged 

  rm -rf $build_dir
fi

