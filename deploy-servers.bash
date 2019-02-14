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
  role=$service
  configure_service "$service" "$image" "$role" "$work_dir" "$java_class"
}

# configure a service to path /opt/chipster-web-server
function configure_service {
  service=$1
  image=$2
  role=$3
  work_dir=$4
  java_class=$5
    
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
  > $template_dir/$service/dc.yaml
  
  # configure ports for services that have them
  admin_port_index=0

  if [ "$create_api_service" != "null" ]; then
  	
    admin_port_index=1
    patch_kind_and_name $template_dir/$service/dc.yaml DeploymentConfig $service "
      spec.template.spec.containers[0].ports[0].containerPort: $api_port
      spec.template.spec.containers[0].ports[0].name: api
      spec.template.spec.containers[0].ports[0].protocol: TCP
    " false
    
    # create OpenShift service
    oc process -f templates/java-server/java-server-api-service.yaml --local \
    -p NAME=$service \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    > $template_dir/$service/api-service.yaml
  fi
    
  if [ "$create_api_route" != "null" ]; then
  
    # create OpenShift service
    oc process -f templates/java-server/java-server-api-route.yaml --local \
    -p NAME=$service \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    > $template_dir/$service/api-route.yaml  
        
    ip_whitelist="$(get_deploy_config ip-whitelist-api)"
    
    if [ -n "$ip_whitelist" ]; then
      apply_firewall $template_dir/$service/api-route.yaml "$ip_whitelist"
    else
      echo "no firewall configured for route $service"  
    fi
  fi
  
  if [ "$create_admin_service_and_route" != "null" ]; then
  
    patch_kind_and_name $template_dir/$service/dc.yaml DeploymentConfig $service "
      spec.template.spec.containers[0].ports[$admin_port_index].containerPort: $admin_port
      spec.template.spec.containers[0].ports[$admin_port_index].name: admin
      spec.template.spec.containers[0].ports[$admin_port_index].protocol: TCP
    " false
  
    # create service and route
    oc process -f templates/java-server/java-server-admin.yaml --local \
    -p NAME=$service \
    -p PROJECT=$PROJECT \
    -p DOMAIN=$DOMAIN \
    > $template_dir/$service/admin.yaml
    
    ip_whitelist="$(get_deploy_config ip-whitelist-admin)"
    if [ -n "$ip_whitelist" ]; then
      apply_firewall $template_dir/$service/admin.yaml "$ip_whitelist"
    else
      echo "no firewall configured for route $service-admin" 
    fi
  fi
  
  # merge to one file for each service to make it easier to know the right file names for patches 
  yq merge --append $template_dir/$service/*.yaml > $template_dir/$service.yaml
  rm $template_dir/$service/*.yaml
  rmdir $template_dir/$service
}

function get_deploy_config {

  key="$1"

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

private_config_path="../chipster-private/confs"

deploy_config_path_shared="$private_config_path/chipster-all/deploy.yaml"
deploy_config_path_project="$private_config_path/$PROJECT.$DOMAIN/deploy.yaml"

chipster_defaults_path="../chipster-web-server/src/main/resources/chipster-defaults.yaml"

mylly=$(get_deploy_config mylly)
if [ -z "$mylly" ]; then  
  mylly=false
fi

shibboleth=$(get_deploy_config shibboleth)


image_project=$(get_deploy_config image_project)
if [ -z "$image_project" ]; then
  echo "image_project is not configure, assuming all images are found from the current project"
  image_project=$PROJECT
fi

build_dir="build"
template_dir="$build_dir/parts"

rm -rf $build_dir
mkdir -p $template_dir

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

configure_service toolbox toolbox toolbox /opt/chipster-web-server &
configure_service type-service chipster-web-server-js type-service /opt/chipster-web-server &
configure_service web-server web-server web-server /opt/chipster-web-server &
configure_service comp comp comp /opt/chipster/comp &

if [ "$mylly" = true ]; then
  configure_service comp-mylly comp-mylly comp /opt/chipster/comp &
else
  echo "skipping mylly"
fi

if [ -n "$shibboleth" ]; then
  
  if oc get dc haka -o json | jq '.spec.template.spec.containers[0].volumeMounts[0].mountPath' | grep logs; then
    echo "dc haka was patched with earlier version of this script. Move "logs" and "confs" to be the last in the volumes and volumeMounts arrays."
    exit 1
  else
  
    # it would be nicer if the shibboleth script would only create the template locally and we could patch before it's 
    # applied to the server. Unfortunately it has created the object already on the server, so we have to patch it there for now   
    echo "configure $shibboleth"
    
    json="$(oc get dc haka -o json)"
    echo "$json" \
      | jq '.spec.template.spec.containers[0].volumeMounts[3]={"mountPath": "/opt/chipster-web-server/logs", "name": "logs"}' \
      | jq '.spec.template.spec.containers[0].volumeMounts[4]={"mountPath": "/opt/chipster-web-server/conf", "name": "conf"}' \
      | jq '.spec.template.spec.volumes[3]={"emptyDir": {}, "name": "logs"}' \
	  | jq '.spec.template.spec.volumes[4]={"name": "conf", "secret": {"defaultMode": 420, "secretName": "haka-conf"}}' \
	  | oc apply -f -
	  
	m2m_port=$(yq r $chipster_defaults_path url-m2m-int-auth | cut -d : -f 3) || true  
	
	patch_kind_and_name $template_dir/auth.yaml DeploymentConfig auth "
      spec.template.spec.containers[0].ports[2].containerPort: $m2m_port
      spec.template.spec.containers[0].ports[2].name: m2m
      spec.template.spec.containers[0].ports[2].protocol: TCP
    " false
    
    oc apply -f templates/auth-m2m.yaml
  fi
else
  echo "skipping shibboleth"
fi

wait


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
  
  oc get dc job-history-postgres -o yaml | yq w - spec.replicas 0 | oc apply -f -
else
  oc get dc job-history-postgres -o yaml | yq w - spec.replicas 1 | oc apply -f -
fi

sharedScriptPath="$private_config_path/chipster-all/chipster-template-patch.bash"
projectScriptPath="$private_config_path/$PROJECT.$DOMAIN/chipster-template-patch.bash"

if [ -f $sharedScriptPath ]; then
  echo "apply shared customizations in $sharedScriptPath"
  bash $sharedScriptPath $template_dir
fi

if [ -f $projectScriptPath ]; then
  echo "apply project specific customizations in $projectScriptPath"
  bash $projectScriptPath $template_dir
fi
 
template="$build_dir/chipster_template.yaml"
yq merge --append $template_dir/*.yaml > $template

echo "apply the template to the server"
apply_out="$build_dir/apply.out"
oc apply -f $template | tee $apply_out | grep -v unchanged
echo $(cat $apply_out | grep unchanged | wc -l) objects unchanged 

rm -rf $build_dir