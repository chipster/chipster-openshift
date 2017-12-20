#!/bin/bash

source script-utils/deploy-utils.bash

PROJECT=$(get_project)
DOMAIN=$(get_domain)

echo
echo "Deploy all for $PROJECT.$DOMAIN"
echo

if [[ $(oc get dc) ]] || [[ $(oc get service) ]] || [[ $(oc get routes) ]] ; then
  echo "The project is not empty. Run the following command to remove all deployments:"
  echo ""
  echo "    oc delete dc --all; oc delete service --all; oc delete routes --all; oc delete pods --all"
  echo ""
  echo "and if your want to remove volumes too:"
  echo ""
  echo "    oc delete pvc --all"
  echo ""
  exit 1
fi 

set -e
set -x

deploy_java_service auth fi.csc.chipster.auth.AuthenticationService
add_volume auth security 1G

deploy_java_service service-locator fi.csc.chipster.servicelocator.ServiceLocator

# oc delete route session-db-events && oc delete service session-db-events
deploy_java_service session-db fi.csc.chipster.sessiondb.SessionDb
oc expose dc session-db --port=8005 --name session-db-events
oc create route edge --service session-db-events --port=8005 --insecure-policy=Redirect


deploy_java_service file-broker fi.csc.chipster.filebroker.FileBroker
add_volume file-broker storage 500G

deploy_java_service scheduler fi.csc.chipster.scheduler.Scheduler

deploy_java_service session-worker fi.csc.chipster.sessionworker.SessionWorker
# doesn't work yet in the OpenShift 1.4, session-worker will send dummy bytes for now to keep the connection open 
oc annotate route session-worker --overwrite haproxy.router.opensfhit.io/timeout=300s


deploy_js_service type-service

deploy_service web-server
# use the root route
#oc expose service web-server --hostname=$PROJECT.$DOMAIN
oc create route edge --service web-server --port 8000 --hostname=$PROJECT.$DOMAIN --insecure-policy=Redirect
 
deploy_service2 comp
retry oc volume dc/comp --add --type=persistentVolumeClaim --claim-mode=ReadWriteMany --claim-size=650G --mount-path /mnt/tools --claim-name tools
# retry oc volume dc/comp --add --type=persistentVolumeClaim --claim-mode=ReadWriteMany --claim-size=100G --mount-path /mnt/tools --claim-name tools
retry oc volume dc/comp --add --type=persistentVolumeClaim --claim-mode=ReadWriteOnce --claim-size=100G --mount-path /opt/chipster/comp/jobs-data --claim-name comp-jobs-data
#retry oc set volume dc/comp --add -t emptyDir --mount-path /opt/chipster-web-server/jobs-data

deploy_service toolbox
# needed for genome parameters
retry oc volume dc/toolbox --add -t pvc --mount-path /mnt/tools --claim-name tools

oc new-app h2 --name auth-h2
oc volume dc/auth-h2 --add --type=persistentVolumeClaim --claim-mode=ReadWriteMany --claim-size=1G --mount-path /opt/h2-data --claim-name auth-h2

oc new-app h2 --name session-db-h2
oc volume dc/session-db-h2 --add --type=persistentVolumeClaim --claim-mode=ReadWriteMany --claim-size=10G --mount-path /opt/h2-data --claim-name session-db-h2

# for tools-bin download
oc new-app base
retry oc set volume  dc/base --add -t pvc --mount-path /mnt/tools --claim-name tools

set +e
set +x

echo '------------------------------------------------------------------------------'
echo '# 1) Download tools by running the following commands:'
echo '# login to the container'
echo 'oc rsh dc/base bash'
echo 'mkdir -p /mnt/tools/current'
echo 'cd /mnt/tools/current'
echo ''
echo '# download the list of packages'
echo 'curl http://vm0151.kaj.pouta.csc.fi/artefacts/create_tools_images/194/parts/files.txt | grep tar.lz4$ > files.txt'
echo ''
echo '# download and extract the packages in parallel'
echo 'time cat files.txt | parallel -j4 "curl http://vm0151.kaj.pouta.csc.fi/artefacts/create_tools_images/194/parts/{} | lz4c -d | tar -x"'
echo ''
echo '# logout from the container'
echo 'exit'
echo ''
echo '# delete the container'
echo 'oc delete dc base'
echo ''
echo '# Optionally, run the following in the container to fix dstat and other programs requiring a username'
echo 'echo "chipster:x:$(id -u):$(id -g)::/tmp:/bin/bash" >> /etc/passwd'
echo '------------------------------------------------------------------------------'
echo '# 2) Configure user accounts in /opt/chipster-web-server/security/users on auth'
echo '------------------------------------------------------------------------------'