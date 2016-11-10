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

# deploy

# oc delete route auth && oc delete service auth && oc delete dc auth && oc delete pvc auth-database
oc new-app auth

oc set volume dc/auth --add -t emptyDir --mount-path /opt/chipster-web-server/logs

oc set volume dc/auth --add --name database -t pvc --mount-path /opt/chipster-web-server/database \
--claim-name=auth-database --claim-size=1G --overwrite

oc expose dc auth --port=8002


# oc delete dc service-locator && oc delete service service-locator

oc new-app service-locator \
-e authentication_service=http://auth:8002/ \
-e authentication_service_pub=http://auth-$PROJECT.$DOMAIN/ \
-e session_db=http://session-db:8004/ \
-e session_db_events=ws://session-db-events:8005/ \
-e session_db_pub=http://session-db-$PROJECT.$DOMAIN/ \
-e session_db_events_pub=ws://session-db-events-$PROJECT.$DOMAIN/ \
-e file_broker=http://file-broker:8007/ \
-e file_broker_pub=http://file-broker-$PROJECT.$DOMAIN/ \
-e scheduler=ws://scheduler:8006/ \
-e toolbox_url=http://toolbox:8008/ \
-e toolbox_url_pub=http://toolbox-$PROJECT.$DOMAIN/

oc set volume dc/service-locator --add -t emptyDir --mount-path /opt/chipster-web-server/logs

oc expose dc service-locator --port=8003 &&\
oc expose service service-locator


# oc delete dc session-db && oc delete service session-db && oc delete pvc session-db-database && oc delete route session-db && oc delete route session-db-events

oc new-app session-db \
-e service_locator=http://service-locator:8003

oc set volume dc/session-db --add -t emptyDir --mount-path /opt/chipster-web-server/logs &&\
oc set volume dc/session-db --add --name database -t pvc --mount-path /opt/chipster-web-server/database \
--claim-name=session-db-database --claim-size=1G --overwrite

oc expose dc session-db --port=8004 --name session-db &&\
oc expose dc session-db --port=8005 --name session-db-events &&\
oc expose service session-db &&\
oc expose service session-db-events


# oc delete dc file-broker && oc delete service file-broker && oc delete route file-broker && oc delete pvc file-broker-storage

oc new-app file-broker \
-e service_locator=http://service-locator:8003

oc set volume dc/file-broker --add -t emptyDir --mount-path /opt/chipster-web-server/logs &&\
oc set volume dc/file-broker --add --name storage -t pvc --mount-path /opt/chipster-web-server/storage \
--claim-name=file-broker-storage --claim-size=4G --overwrite

oc expose dc file-broker --port=8007 &&\
oc expose service file-broker


oc new-app scheduler \
-e service_locator=http://service-locator:8003

oc set volume dc/scheduler --add -t emptyDir --mount-path /opt/chipster-web-server/logs

// only a service is needed, but not a route, because only comp has to connect to the scheduler 
oc expose dc scheduler --port=8006


oc new-app session-worker \
-e service_locator=http://service-locator:8003

oc set volume dc/session-worker --add -t emptyDir --mount-path /opt/chipster-web-server/logs
 
oc expose dc session-worker --port=8009 &&\
oc expose service session-worker


oc new-app toolbox

oc expose service toolbox

oc set volume dc/toolbox --add -t emptyDir --mount-path /opt/chipster-web-server/logs


oc new-app web-server

oc expose dc web-server --port=8000 &&\
oc expose service web-server --hostname=$PROJECT.$DOMAIN

oc set volume dc/web-server --add -t emptyDir --mount-path /opt/chipster-web-server/logs


oc new-app comp \
-e service_locator=http://service-locator:8003 \
-e toolbox_url=http://toolbox:8008

oc volume dc/comp --add --type=persistentVolumeClaim --claim-mode=ReadWriteMany --claim-size=500G --mount-path /opt/chipster/tools --claim-name tools --mount-path /opt/chipster/tools &&\
oc set volume dc/comp --add -t emptyDir --mount-path /opt/chipster-web-server/logs &&\
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
