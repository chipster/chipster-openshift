#!/bin/bash

source script-utils/deploy-utils.bash

PROJECT=$(get_project)
DOMAIN=$(get_domain)

echo "$DOMAIN"
echo "Create secrets for $PROJECT.$DOMAIN"
echo

#if [[ $(oc get all) ]]
#then
#  echo "The project is not empty"
#  exit 1
#fi 

set -e
set -x

function get_db_password {
	role="$1"
	pod=$(oc get pod -o name | grep -v deploy | grep $role | head -n 1)
	conf=$(oc rsh -c $role $pod cat conf/chipster.yaml)
	password=$(echo "$conf" | grep $role | grep db-pass | cut -d ":" -f 2 | tr -d '\r')
	echo $password
}

function generate_password {
	openssl rand -base64 15
}

# generate service passwords

function create_password {
  service=$1
  config_key=service-password-${service}
  
  echo $config_key: $(generate_password) | tee conf/$service.yaml >> conf/auth.yaml
}

function create_sso_password {
  service=$1
  config_key=sso-service-password-${service}
  
  echo $config_key: $(generate_password) | tee conf/$service.yaml >> conf/auth.yaml
}

# generate configs and save them as openshift secrets

rm -rf conf/*

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
	haka"
	

authenticated_services=$(cat ../chipster-web-server/conf/chipster-defaults.yaml | grep ^service-password- | cut -d : -f 1 | sed s/service-password-//)

for service in $authenticated_services; do
	create_password $service
done


# get the db password from the existing instance
auth_db_pass=$(get_db_password auth)
session_db_pass=$(get_db_password session-db)

# use these instead to generate new passwords for a new installation  
#auth_db_pass=$(generate_password)
#session_db_pass=$(generate_password)

echo auth-db-url: jdbc:h2:tcp://auth-h2:1521/database/chipster-auth-db >> conf/auth.yaml
echo auth-db-user: sa >> conf/auth.yaml
echo auth-db-pass: $auth_db_pass >> conf/auth.yaml

# sso has to be enabled explicitly
echo url-m2m-bind-auth: http://0.0.0.0:8013 >> conf/auth.yaml

echo session-db-url: jdbc:h2:tcp://session-db-h2:1521/database/chipster-session-db >> conf/session-db.yaml
echo session-db-user: sa >> conf/session-db.yaml
echo session-db-pass: $session_db_pass >> conf/session-db.yaml

bash script-utils/generate-urls.bash $PROJECT $DOMAIN >> conf/service-locator.yaml

# Haka Single sign-on
create_sso_password haka
echo url-ext-haka: https://haka-$PROJECT.$DOMAIN >> conf/service-locator.yaml

function create_secret {
  service=$1
  secret_name=${service}-conf
  if [[ $(oc get secret $secret_name) ]]; then
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
	echo "url-int-service-locator: http://service-locator:8003" >> conf/$service.yaml
	
	create_secret $service
done

# Configuration for the Angular app
if [[ $(oc get secret web-server-app-conf) ]]; then
  oc delete secret web-server-app-conf  
fi

mkdir -p conf/web-server-app-conf

cat ../chipster-web/src/assets/conf/chipster.yaml | \
  sed "s#^service-locator: http://localhost:8003#service-locator: https://service-locator-$PROJECT.$DOMAIN#" \
  > conf/web-server-app-conf/chipster.yaml

oc create secret generic web-server-app-conf \
  --from-file=chipster.yaml=conf/web-server-app-conf/chipster.yaml

rm -rf conf/*