#!/bin/bash

# Create configuration files for Chipster app backend and store them to OpenShift secrets
# 
# Configuration is done in several steps to avoid duplication of configuration when 
# maintaining a large number of deployments (i.e. OpenShift projects)
#  
# 1. chipstser-web-server/src/main/resources/chipster-defaults.yaml
#    - Chipster defaults, ready to run on a laptop for development
# 2. this script (create-secrets.bash)
#    - Generic OpenShift deployment
# 3. chipster-private/confs/chipster-all/
#    - Customizations to all deployments in this organization (e.g. our accounts are called csc/ instead of jaas/)
# 4. chipster-private/confs/$PROJECT.$DOMAIN/
#    - Configuration of single project

source scripts/utils.bash

PROJECT=$(get_project)
DOMAIN=$(get_domain)

echo "$DOMAIN"
echo "Create secrets for $PROJECT.$DOMAIN"
echo

set -e

# generate service passwords

function merge_custom_confs {
  file=$1

  chipsterAllConfPath="../chipster-private/confs/chipster-all/$file"
  projectConfPath="../chipster-private/confs/$PROJECT.$DOMAIN/$file"
  tempConfPath="$build_dir/${file}_merge_custom_confs_temp"
  resultConfPath="$build_dir/$file"
  		
  if [ -f $chipsterAllConfPath ]; then
    echo "apply configuration $chipsterAllConfPath" 	
    mv $resultConfPath $tempConfPath
	yq merge $chipsterAllConfPath $tempConfPath > $resultConfPath
	rm $tempConfPath
  fi
  
  if [ -f $projectConfPath ]; then
    echo "apply configuration $projectConfPath"		
    mv $resultConfPath $tempConfPath
	yq merge $projectConfPath $tempConfPath > $resultConfPath
	rm $tempConfPath
  fi    
}

function create_secret_for_service {

	service="$1"
	subproject="$2"
  	subproject_postfix="$3"
  	secret_name="${service}$subproject_postfix"
  
  	# apply custom configurations
  	merge_custom_confs $service.yaml
	
	secret_file="$configured_objects_dir/${service}.json"
		
	get_secret $secret_name $subproject > $secret_file
	add_file_to_secret $secret_file chipster.yaml $build_dir/${service}.yaml
}


subproject="$1"

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
fi

# generate configs and save them as openshift secrets

# better to do this outside repo
build_dir=$(make_temp chipster-openshift_create-secrets)
echo -e "build dir is \033[33;1m$build_dir\033[0m"

configured_objects_dir="$build_dir/configured-objects"

mkdir -p $configured_objects_dir

services="session-db 
	service-locator
	scheduler
	comp
	file-broker
	file-storage
	session-worker
	auth
	toolbox
	web-server
	type-service
	haka
	backup
	job-history"
	
	# file-storage-single

authenticated_services=$(cat ../chipster-web-server/src/main/resources/chipster-defaults.yaml | grep ^service-password- | cut -d : -f 1 | sed s/service-password-//)

echo "configure service passwords"

passwords="$(oc get secret passwords$subproject_postfix -o json)"

for service in $authenticated_services; do

  config_key=service-password-${service}

  service_password_base64="$(echo "$passwords" | jq -r .data[\"$config_key\"])"

  if [ $service_password_base64 == "null" ]; then
    echo "There is no password for $config_key. Run 'bash generate-passwords.bash' first."
	# TODO use exit trap
	rm -rf $build_dir
	exit 1
  fi
  service_password="$(echo "$service_password_base64" | base64 --decode)"
  
  echo $config_key: $service_password | tee $build_dir/$service.yaml >> $build_dir/auth.yaml
done

# get the (multiline) private key from the passwords, and prefix each line with a space character to make it a yaml block 
jws_private_key_auth="$(      echo "$passwords" | jq -r .data[\"jws-private-key-auth\"]       | base64 --decode | sed -e 's/^/ /')"
jws_private_key_session_db="$(echo "$passwords" | jq -r .data[\"jws-private-key-session-db\"] | base64 --decode | sed -e 's/^/ /')"

echo -e "jws-private-key-auth: |\n$jws_private_key_auth"             >> $build_dir/auth.yaml
echo -e "jws-private-key-session-db: |\n$jws_private_key_session_db" >> $build_dir/session-db.yaml

# variable isn't needed anymore, clear it
passwords=""

echo "get db passwords"

auth_db_pass=$(get_db_password passwords$subproject_postfix auth)
session_db_db_pass=$(get_db_password passwords$subproject_postfix session-db)
job_history_db_pass=$(get_db_password passwords$subproject_postfix job-history)

echo db-url-auth: jdbc:postgresql://auth-postgres$subproject_postfix:5432/auth_db | tee -a $build_dir/backup.yaml >> $build_dir/auth.yaml
echo db-pass-auth: $auth_db_pass | tee -a $build_dir/backup.yaml >> $build_dir/auth.yaml

echo db-url-job-history: jdbc:postgresql://job-history-postgres$subproject_postfix:5432/job_history_db | tee -a $build_dir/backup.yaml >> $build_dir/job-history.yaml
echo db-pass-job-history: $job_history_db_pass | tee -a $build_dir/backup.yaml >> $build_dir/job-history.yaml

echo "create monitoring password"

# monitoring password
monitoring_password=$(generate_password)
echo auth-monitoring-password:  $monitoring_password >> $build_dir/auth.yaml
secret_file="$configured_objects_dir/monitoring.json"
get_secret monitoring$subproject_postfix $subproject > $secret_file
add_literal_to_secret $secret_file password $monitoring_password


echo db-url-session-db: jdbc:postgresql://session-db-postgres$subproject_postfix:5432/session_db_db | tee -a $build_dir/backup.yaml >> $build_dir/session-db.yaml
echo db-pass-session-db: $session_db_db_pass | tee -a $build_dir/backup.yaml >> $build_dir/session-db.yaml

echo "generate urls"

bash scripts/generate-urls.bash $PROJECT $DOMAIN $subproject >> $build_dir/service-locator.yaml

echo "generate secret for each service"

for service in $services; do	
	echo "url-int-service-locator: http://service-locator$subproject_postfix" >> $build_dir/$service.yaml
	
	create_secret_for_service $service $subproject $subproject_postfix
done

# Mylly
# this should be in the project specific configuration, but it doesn't support custom scripts yet
cp $build_dir/comp.yaml $build_dir/comp-mylly.yaml
create_secret_for_service comp-mylly $subproject $subproject_postfix

echo "configure app"

# Configuration for the Angular app

mkdir -p $build_dir/web-server-app

cat ../chipster-web/src/assets/conf/chipster.yaml \
  | yq w - service-locator https://service-locator${subproject_postfix}-$PROJECT.$DOMAIN \
  > $build_dir/web-server-app/chipster.yaml
  
merge_custom_confs web-server-app/chipster.yaml
   	
secret_file="$configured_objects_dir/web-server-app.json"
	
get_secret web-server-app$subproject_postfix $subproject > $secret_file
add_file_to_secret $secret_file chipster.yaml $build_dir/web-server-app/chipster.yaml

echo "apply to server"

oc apply -f "$configured_objects_dir"

echo "delete build dir $build_dir"
rm -rf $build_dir