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

function create_sso_password {
  service=$1
  config_key=sso-service-password-${service}
  
  echo $config_key: $(generate_password) | tee $build_dir/$service.yaml >> $build_dir/auth.yaml
}

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
		
	get_secret $secret_name $subproject $service > $secret_file
	add_file_to_secret $secret_file chipster.yaml $build_dir/${service}.yaml
}


subproject="$1"

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
fi

# generate configs and save them as openshift secrets

# contains passwords, don't commit
build_dir="build-DO-NOT_COMMIT"
configured_objects_dir="$build_dir/configured-objects"

rm -rf $build_dir/*
mkdir -p $configured_objects_dir

services="session-db 
	service-locator
	scheduler
	comp
	file-broker
	session-worker
	auth
	toolbox
	web-server
	type-service
	haka
	backup
	job-history"
	

authenticated_services=$(cat ../chipster-web-server/src/main/resources/chipster-defaults.yaml | grep ^service-password- | cut -d : -f 1 | sed s/service-password-//)

echo "configure service passwords"

passwords="$(oc get secret passwords$subproject_postfix -o json)"

for service in $authenticated_services; do

  config_key=service-password-${service}
  service_password="$(echo "$passwords" | jq -r .data[\"$config_key\"] | base64 --decode)"
  
  echo $config_key: $service_password | tee $build_dir/$service.yaml >> $build_dir/auth.yaml
done

passwords=""


echo "{}" >  $build_dir/backup.yaml
merge_custom_confs backup.yaml

echo "get db passwords"

auth_db_pass=$(get_db_password passwords$subproject_postfix auth)
session_db_db_pass=$(get_db_password passwords$subproject_postfix session-db)
job_history_db_pass=$(get_db_password passwords$subproject_postfix job-history)

echo db-url-auth: jdbc:postgresql://auth-postgres$subproject_postfix:5432/auth_db | tee -a $build_dir/backup.yaml >> $build_dir/auth.yaml
echo db-pass-auth: $auth_db_pass | tee -a $build_dir/backup.yaml >> $build_dir/auth.yaml

echo db-url-job-history: jdbc:postgresql://job-history-postgres$subproject_postfix:5432/job_history_db | tee -a $build_dir/backup.yaml >> $build_dir/job-history.yaml
echo db-pass-job-history: $job_history_db_pass | tee -a $build_dir/backup.yaml >> $build_dir/job-history.yaml

# DB restore from backup
#
# - go to pouta.csc.fi -> Object Store -> Containers to see the backups. Copy the name of the backup to the config item below. 
# - uncomment the row(s) below
# - run "bash create-secrets.bash" and "bash rollout-services.bash" to prevent the actual service from starting. Backup service won't restore yet because the DB isn't empty
# - delete the pvc of those databases
# - run "bash create-pvcs.bash" to create new volumes
# - run "oc rollout latest <service>-h2" to make the database recognize that the DB is gone
# - run "bash rollout-services.bash" which should now start the restore (check from the backup service's logs)
# - comment the following lines again
# - run "bash create-secrets.bash" and "bash rollout-services.bash" to remove the restore configuration and start the services
#echo db-restore-key-auth: auth-db-backup_2018-05-24T12:37.sql | tee -a $build_dir/backup.yaml >> $build_dir/auth.yaml
#echo db-restore-key-session-db: session-db-db-backup_2018-09-05T05:10:00.230Z.sql | tee -a $build_dir/backup.yaml >> $build_dir/session-db.yaml

echo "create monitoring password"

# monitoring password
monitoring_password=$(generate_password)
echo auth-monitoring-password:  $monitoring_password >> $build_dir/auth.yaml
secret_file="$configured_objects_dir/monitoring.json"
get_secret monitoring$subproject_postfix $subproject monitoring > $secret_file
add_literal_to_secret $secret_file password $monitoring_password


echo db-url-session-db: jdbc:postgresql://session-db-postgres$subproject_postfix:5432/session_db_db | tee -a $build_dir/backup.yaml >> $build_dir/session-db.yaml
echo db-pass-session-db: $session_db_db_pass | tee -a $build_dir/backup.yaml >> $build_dir/session-db.yaml

echo "generate urls"

bash scripts/generate-urls.bash $PROJECT $DOMAIN $subproject >> $build_dir/service-locator.yaml

echo "generate haka password"

# Haka Single sign-on
# this should be in the project specific configuration, but it doesn't support variables yet 
create_sso_password haka
echo url-ext-haka: https://$PROJECT.$DOMAIN/sso/haka >> $build_dir/service-locator.yaml

echo "generate secret for each service"

for service in $services; do	
	echo "url-int-service-locator: http://service-locator$subproject_postfix" >> $build_dir/$service.yaml
	
	create_secret_for_service $service $subproject $subproject_postfix
done

# Mylly
# this should be in the project specific configuration, but it doesn't support custom scripts yet
cp $build_dir/comp.yaml $build_dir/comp-mylly.yaml
create_secret_for_service comp-mylly $subproject $subproject_postfix

add_file_to_secret $configured_objects_dir/comp.json 		comp-chipster-config.xml ../chipster-web-server/conf/comp-chipster-config.xml
add_file_to_secret $configured_objects_dir/comp-mylly.json 	comp-chipster-config.xml ../chipster-web-server/conf/comp-chipster-config.xml
add_file_to_secret $configured_objects_dir/auth.json jaas.config ../chipster-private/confs/rahti-int/jaas.config

echo "configure app"

# Configuration for the Angular app

mkdir -p $build_dir/web-server-app

cat ../chipster-web/src/assets/conf/chipster.yaml \
  | yq w - service-locator https://service-locator${subproject_postfix}-$PROJECT.$DOMAIN \
  > $build_dir/web-server-app/chipster.yaml
  
merge_custom_confs web-server-app/chipster.yaml
  
yq n modules [] \
  | yq w - modules[0] Kielipankki \
  | yq w - manual-path assets/manual/kielipankki/manual/ \
  | yq w - manual-tool-postfix .en.src.html \
  | yq w - app-name Mylly \
  | yq w - custom-css assets/manual/kielipankki/manual/app-mylly-styles.css \
  | yq w - favicon assets/manual/kielipankki/manual/app-mylly-favicon.png \
  | yq w - home-path assets/manual/kielipankki/manual/app-home.html \
  | yq w - home-header-path assets/manual/kielipankki/manual/app-home-header.html \
  | yq w - contact-path assets/manual/kielipankki/manual/app-contact.html \
   > $build_dir/web-server-app/mylly.yaml
   	
secret_file="$configured_objects_dir/web-server-app.json"
	
get_secret web-server-app$subproject_postfix $subproject web-server > $secret_file
add_file_to_secret $secret_file chipster.yaml $build_dir/web-server-app/chipster.yaml
add_file_to_secret $secret_file mylly.yaml $build_dir/web-server-app/mylly.yaml

echo "apply to server"

oc apply -f "$configured_objects_dir"

rm -rf $build_dir