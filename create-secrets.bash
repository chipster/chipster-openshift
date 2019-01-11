#!/bin/bash

# Create configuration files for Chipster app backend and store them to OpenShift secrets
# 
# Configuration is done in several steps to avoid duplication of configuration when 
# maintaining a large number of deployments (i.e. OpenShift projects)
#  
# 1. chipstser-web-server/src/main/resources/chipster-defaults.yaml
#    - Chipster defaults, ready to run on laptop for development
# 2. this script (create-secrets.bash)
#    - Generic OpenShift deployment
# 3. chipster-private/confs/chipster-all/
#    - Customizations to all deployments in this organization (e.g. our accounts are called csc/ instead of jaas/)
# 4. chipster-private/confs/$PROJECT.$DOMAIN/
#    - Configuration of single project

source script-utils/deploy-utils.bash

echo "$DOMAIN"
echo "Create secrets for $PROJECT.$DOMAIN"
echo

set -e

# generate service passwords

function write_password {
  service=$1
  config_key=service-password-${service}
  
  echo $config_key: $(get_service_password $service) | tee conf/$service.yaml >> conf/auth.yaml
}

function create_sso_password {
  service=$1
  config_key=sso-service-password-${service}
  
  echo $config_key: $(generate_password) | tee conf/$service.yaml >> conf/auth.yaml
}

function merge_custom_confs {
  file=$1

  chipsterAllConfPath="../chipster-private/confs/chipster-all/$file"
  projectConfPath="../chipster-private/confs/$PROJECT.$DOMAIN/$file"
  tempConfPath="conf/${file}_merge_custom_confs_temp"
  resultConfPath="conf/$file"
  		
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

function create_secret {
  service=$1
  secret_name=${service}-conf
  
  # apply custom configurations
  merge_custom_confs $service.yaml
  
  # delete old secret
  if oc get secret $secret_name > /dev/null 2>&1; then
  	oc delete secret $secret_name  
  fi
	
  # create new secret
  # copy the old config file for comp, because mounting the secret will hide other files in the conf dir
  oc create secret generic $secret_name \
  	--from-file=chipster.yaml=conf/${service}.yaml \
  	--from-file=comp-chipster-config.xml=../chipster-web-server/conf/comp-chipster-config.xml \
  	--from-file=jaas.config=../chipster-private/confs/rahti-int/jaas.config
}


# generate configs and save them as openshift secrets

rm -rf conf/*
mkdir -p conf

services="session-db 
	service-locator
	scheduler
	comp
	file-broker
	session-worker
	proxy
	auth
	toolbox
	web-server
	type-service
	haka
	backup
	job-history"
	

authenticated_services=$(cat ../chipster-web-server/src/main/resources/chipster-defaults.yaml | grep ^service-password- | cut -d : -f 1 | sed s/service-password-//)

for service in $authenticated_services; do
	write_password $service
done


echo "{}" >  conf/backup.yaml
merge_custom_confs backup.yaml

auth_db_pass=$(get_db_password auth)
session_db_db_pass=$(get_db_password session-db)
job_history_db_pass=$(get_db_password job-history)

echo db-url-auth: jdbc:postgresql://auth-postgres:5432/auth_db | tee -a conf/backup.yaml >> conf/auth.yaml
echo db-pass-auth: $auth_db_pass | tee -a conf/backup.yaml >> conf/auth.yaml

echo db-url-job-history: jdbc:postgresql://job-history-postgres:5432/job_history_db | tee -a conf/backup.yaml >> conf/job-history.yaml
echo db-pass-job-history: $job_history_db_pass | tee -a conf/backup.yaml >> conf/job-history.yaml

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
#echo db-restore-key-auth: auth-db-backup_2018-05-24T12:37.sql | tee -a conf/backup.yaml >> conf/auth.yaml
#echo db-restore-key-session-db: session-db-db-backup_2018-09-05T05:10:00.230Z.sql | tee -a conf/backup.yaml >> conf/session-db.yaml

# monitoring password
monitoring_password=$(generate_password)
echo auth-monitoring-password:  $monitoring_password >> conf/auth.yaml
if oc get secret monitoring-conf > /dev/null 2>&1; then
  oc delete secret monitoring-conf
fi
oc create secret generic monitoring-conf --from-literal=password=$monitoring_password

echo 'db-url-session-db: jdbc:postgresql://session-db-postgres:5432/session_db_db' | tee -a conf/backup.yaml >> conf/session-db.yaml
echo db-pass-session-db: $session_db_db_pass | tee -a conf/backup.yaml >> conf/session-db.yaml

bash script-utils/generate-urls.bash $PROJECT $DOMAIN >> conf/service-locator.yaml

# Haka Single sign-on
# this should be in the project specific configuration, but it doesn't support variables yet 
create_sso_password haka
echo url-ext-haka: https://$PROJECT.$DOMAIN/sso/haka >> conf/service-locator.yaml

for service in $services; do
	# deployment assumes that there is a configuration secret for each service	
	echo "url-int-service-locator: http://service-locator" >> conf/$service.yaml
		
	create_secret $service
done

# Mylly
# this should be in the project specific configuration, but it doesn't support custom scripts yet
cp conf/comp.yaml conf/comp-mylly.yaml
create_secret comp-mylly


# Configuration for the Angular app
if oc get secret web-server-app-conf > /dev/null 2>&1; then
  oc delete secret web-server-app-conf  
fi

mkdir -p conf/web-server-app-conf

cat ../chipster-web/src/assets/conf/chipster.yaml \
  | yq w - service-locator https://service-locator-$PROJECT.$DOMAIN \
  > conf/web-server-app-conf/chipster.yaml
  
merge_custom_confs web-server-app-conf/chipster.yaml
  
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
   > conf/web-server-app-conf/mylly.yaml

oc create secret generic web-server-app-conf \
  --from-file=chipster.yaml=conf/web-server-app-conf/chipster.yaml \
  --from-file=mylly.yaml=conf/web-server-app-conf/mylly.yaml

rm -rf conf/