#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Usgae: deploy.bash PROJECT DOMAIN, e.g. deploy.bash chipster-dev dac-oso.csc.fi"
    exit 0
fi

# check if login is needed
oc get projects > /dev/null

if [ $? -eq 1 ]
then
  oc login
fi

PROJECT=$1
DOMAIN=${$2:-dac-oso.csc.fi}

oc project "$PROJECT"

if [ $? -eq 1 ]
then
  oc new-project "$PROJECT"
fi

if [[ $(oc project -q) != "$PROJECT" ]]
then
  echo "failed to create the project"
  exit 1
fi 

if [[ $(oc get all) ]]
then
  echo "The project is not empty"
  exit 1
fi 

set -e
set -x

# generate service passwords

function create_password {
  service=$1
  config_key=${service}-password
  
  echo $config_key: $(openssl rand -base64 16) | tee conf/$service.yaml >> conf/auth.yaml
}

# generate configs and save them as openshift secrets

rm -f conf/*

create_password session-db
create_password service-locator
create_password scheduler
create_password comp
create_password file-broker
create_password session-worker
create_password proxy

echo "authentication-service: http://auth:8002/
authentication-service-pub: http://auth-$PROJECT.$DOMAIN/
session-db: http://session-db:8004/
session-db-events: ws://session-db-events:8005/
session-db-pub: http://session-db-$PROJECT.$DOMAIN/
session-db-events-pub: ws://session-db-events-$PROJECT.$DOMAIN/
file-broker: http://file-broker:8007/
file-broker-pub: http://file-broker-$PROJECT.$DOMAIN/
scheduler: ws://scheduler:8006/
toolbox-url: http://toolbox:8008/
toolbox-url-pub: http://toolbox-$PROJECT.$DOMAIN/
session-worker: http://session-worker:8009/
session-worker-pub: http://session-worker-$PROJECT.$DOMAIN/" >> conf/service-locator.yaml

echo "service-locator: http://service-locator:8003" >> conf/session-db.yaml
echo "service-locator: http://service-locator:8003" >> conf/file-broker.yaml
echo "service-locator: http://service-locator:8003" >> conf/scheduler.yaml
echo "service-locator: http://service-locator:8003" >> conf/session-worker.yaml
echo "service-locator: http://service-locator:8003" >> conf/comp.yaml

echo "toolbox-url: http://toolbox:8008" >> conf/comp.yaml

# deployment assumes that there is a configuration secret for each service
touch conf/toolbox.yaml
touch conf/web-server.yaml

function create_secret {
  service=$1
  secret_name=${service}-conf
  if [[ $(oc get secret $secret_name) ]]; then
  	oc delete secret $secret_name  
  fi
  // copy the old config file for comp, because mounting the secret will hide other files in the conf dir
  oc create secret generic $secret_name --from-file=chipster.yaml=conf/${service}.yaml --from-file=comp-chipster-config.xml=../chipster-web-server/conf/comp-chipster-config.xml  
}

create_secret auth
create_secret session-db
create_secret service-locator
create_secret scheduler
create_secret comp
create_secret file-broker
create_secret session-worker
create_secret toolbox
create_secret web-server

rm conf/*

# deploy

function deploy_service {
  service=$1
  if [[ $(oc get dc $service 2> /dev/null) ]]; then
  	oc delete dc $service  
  fi
  oc new-app $service
  oc set volume dc/$service --add -t emptyDir --mount-path /opt/chipster-web-server/logs
  oc set volume dc/$service --add -t secret --secret-name ${service}-conf --mount-path /opt/chipster-web-server/conf/
}

# oc delete route auth && oc delete service auth && oc delete pvc auth-database
deploy_service auth
oc set volume dc/auth --add --name database -t pvc --mount-path /opt/chipster-web-server/database --claim-name=auth-database --claim-size=1G --overwrite
oc expose dc auth --port=8002
oc expose service auth


# oc delete dc service-locator && oc delete service service-locator && oc delete route service-locator
deploy_service service-locator
oc expose dc service-locator --port=8003 &&\
oc expose service service-locator


# oc delete service session-db && oc delete pvc session-db-database && oc delete route session-db && oc delete route session-db-events
deploy_service session-db
oc set volume dc/session-db --add --name database -t pvc --mount-path /opt/chipster-web-server/database --claim-name=session-db-database --claim-size=1G --overwrite
oc expose dc session-db --port=8004 --name session-db &&\
oc expose dc session-db --port=8005 --name session-db-events &&\
oc expose service session-db &&\
oc expose service session-db-events


# oc delete service file-broker && oc delete route file-broker && oc delete pvc file-broker-storage

deploy_service file-broker
oc set volume dc/file-broker --add --name storage -t pvc --mount-path /opt/chipster-web-server/storage --claim-name=file-broker-storage --claim-size=100G --overwrite
oc expose dc file-broker --port=8007 &&\
oc expose service file-broker


# oc delete service scheduler
deploy_service scheduler
// only a service is needed, but not a route, because only comp has to connect to the scheduler 
oc expose dc scheduler --port=8006


# oc delete service session-worker && oc delete route session-worker
deploy_service session-worker
oc set volume dc/session-worker --add -t emptyDir --mount-path /opt/chipster-web-server/logs
oc expose dc session-worker --port=8009 &&\
oc expose service session-worker


deploy_service toolbox
oc expose service toolbox


deploy_service web-server
oc expose dc web-server --port=8000
oc expose service web-server --hostname=$PROJECT.$DOMAIN

 
deploy_service comp
oc volume dc/comp --add --type=persistentVolumeClaim --claim-mode=ReadWriteMany --claim-size=500G --mount-path /opt/chipster/tools --claim-name tools --mount-path /opt/chipster/tools
oc set volume dc/comp --add -t emptyDir --mount-path /opt/chipster-web-server/jobs-data

# download tools-bin
oc new-app base
oc set volume  dc/base --add -t pvc --mount-path /opt/chipster/tools --claim-name tools

echo '------------------------------------------------------------------------------'
echo '# 1) Download tools by running the following commands:'
echo '# login to the container'
echo 'oc rsh $(oc get pod -l app=base | grep Running | cut -f 1 -d " ") bash'
echo 'cd /opt/chipster/tools'
echo '# download the list of packages'
echo 'curl http://vm0151.kaj.pouta.csc.fi/artefacts/create_tools_images/194/parts/files.txt | grep tar.lz4$ > files.txt'
echo '# download and extract the packages in parallel'
echo 'time cat files.txt | parallel -j16 "curl http://vm0151.kaj.pouta.csc.fi/artefacts/create_tools_images/194/parts/{} | lz4c -d | tar -x"'
echo '# logout from the container'
echo 'exit'
echo '# delete the container'
echo 'oc delete dc base'
echo ''
echo '# Optionally, run the following in the container to fix dstat and other programs requiring a username
echo 'echo "chipster:x:$(id -u):$(id -g)::/tmp:/bin/bash" >> /etc/passwd'
echo '------------------------------------------------------------------------------'
echo '# 2) Finally go to the OpenShift's Configuration tab of each build which has a GitHub source, copy the Github webhook URL' 
echo '# and paste it to the GitHub's settings page of the repository. Disable the GitHub's SSL check in the webhook's settings.'
echo '------------------------------------------------------------------------------'
