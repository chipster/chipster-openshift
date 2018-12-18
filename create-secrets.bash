#!/bin/bash

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
	

authenticated_services=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep ^service-password- | cut -d : -f 1 | sed s/service-password-//)

for service in $authenticated_services; do
	write_password $service
done

backup_conf="../chipster-private/confs/$PROJECT.$DOMAIN/db-backups.yaml"

if [ -f "$backup_conf" ]; then
  cat $backup_conf >> conf/backup.yaml
fi

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

# sso has to be enabled explicitly
echo url-m2m-bind-auth: http://0.0.0.0:8013 >> conf/auth.yaml

echo auth-jaas-prefix: csc >> conf/auth.yaml
echo session-db-restrict-sharing-to-everyone: csc/example_session_owner >> conf/session-db.yaml

#echo 'db-url-session-db: jdbc:h2:tcp://session-db-h2:1521/database/chipster-session-db;DB_CLOSE_ON_EXIT=FALSE;MULTI_THREADED=TRUE' | tee -a conf/backup.yaml >> conf/session-db.yaml
#echo db-pass-session-db: $session_db_db_pass | tee -a conf/backup.yaml >> conf/session-db.yaml

echo 'db-url-session-db: jdbc:postgresql://session-db-postgres:5432/session_db_db' | tee -a conf/backup.yaml >> conf/session-db.yaml
echo db-pass-session-db: $session_db_db_pass | tee -a conf/backup.yaml >> conf/session-db.yaml

bash script-utils/generate-urls.bash $PROJECT $DOMAIN >> conf/service-locator.yaml

# contact support email settings
cat "../chipster-private/confs/$PROJECT.$DOMAIN/session-worker.yaml" >> conf/session-worker.yaml

# Haka Single sign-on
create_sso_password haka
echo url-ext-haka: https://$PROJECT.$DOMAIN/sso/haka >> conf/service-locator.yaml

function create_secret {
  service=$1
  secret_name=${service}-conf
  if oc get secret $secret_name > /dev/null 2>&1; then
  	oc delete secret $secret_name  
  fi
  # copy the old config file for comp, because mounting the secret will hide other files in the conf dir
  oc create secret generic $secret_name \
  	--from-file=chipster.yaml=conf/${service}.yaml \
  	--from-file=chipster-defaults.yaml=../chipster-web-server/conf/chipster-defaults.yaml \
  	--from-file=comp-chipster-config.xml=../chipster-web-server/conf/comp-chipster-config.xml \
  	--from-file=jaas.config=../chipster-private/confs/rahti-int/jaas.config
}


for service in $services; do
	# deployment assumes that there is a configuration secret for each service	
	echo "url-int-service-locator: http://service-locator" >> conf/$service.yaml
	
	create_secret $service
done

# Mylly
cp conf/comp.yaml conf/comp-mylly.yaml
echo "comp-module-filter-name: kielipankki" >> conf/comp-mylly.yaml
echo "comp-module-filter-mode: include" >> conf/comp-mylly.yaml
create_secret comp-mylly


# Configuration for the Angular app
if oc get secret web-server-app-conf > /dev/null 2>&1; then
  oc delete secret web-server-app-conf  
fi

mkdir -p conf/web-server-app-conf

cat ../chipster-web/src/assets/conf/chipster.yaml \
  | yq w - service-locator https://service-locator-$PROJECT.$DOMAIN \
  | yq w - example-session-owner-user-id csc/example_session_owner \
  > conf/web-server-app-conf/chipster.yaml
  
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