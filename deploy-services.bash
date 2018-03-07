#!/bin/bash

source script-utils/deploy-utils.bash

PROJECT=$(get_project)
DOMAIN=$(get_domain)

echo
echo "Deploy all for $PROJECT.$DOMAIN"
echo

if [[ $(oc get dc) ]] || [[ $(oc get service -o name | grep -v glusterfs-dynamic-) ]] || [[ $(oc get routes) ]] ; then
  echo "The project is not empty. Run the following command to remove all deployments:"
  echo ""
  echo '    oc delete dc --all; oc delete routes --all; oc delete pods --all; for s in $(oc get service -o name | grep -v glusterfs-dynamic-); do oc delete $s; done'
  echo ""
  echo "and if your want to remove volumes too:"
  echo ""
  echo "    oc delete pvc --all"
  echo ""
  exit 1
fi 

set -e
set -x

oc new-app h2 --name auth-h2
add_volume auth-h2 auth-h2-data 1G /opt/h2-data ReadWriteMany

oc new-app h2 --name session-db-h2
add_volume session-db-h2 session-db-h2-data 10G /opt/h2-data ReadWriteMany

deploy_java_service auth fi.csc.chipster.auth.AuthenticationService
add_volume auth auth-security 1G /opt/chipster-web-server/security ReadWriteMany

deploy_java_service service-locator fi.csc.chipster.servicelocator.ServiceLocator

# oc delete route session-db-events && oc delete service session-db-events
deploy_java_service session-db fi.csc.chipster.sessiondb.SessionDb
oc expose dc session-db --port=8005 --name session-db-events
oc create route edge --service session-db-events --port=8005 --insecure-policy=Redirect


deploy_java_service file-broker fi.csc.chipster.filebroker.FileBroker
add_volume file-broker file-broker-storage 200G /opt/chipster-web-server/storage ReadWriteMany

deploy_java_service scheduler fi.csc.chipster.scheduler.Scheduler

deploy_java_service session-worker fi.csc.chipster.sessionworker.SessionWorker
# doesn't work yet in the OpenShift 1.4, session-worker will send dummy bytes for now to keep the connection open 
oc annotate route session-worker --overwrite haproxy.router.opensfhit.io/timeout=300s


deploy_js_service type-service

deploy_service web-server
# use the root route
#oc expose service web-server --hostname=$PROJECT.$DOMAIN
oc create route edge --service web-server --port 8000 --hostname=$PROJECT.$DOMAIN --insecure-policy=Redirect
oc set volume dc/web-server --add -t secret --secret-name web-server-app-conf --mount-path /opt/chipster-web/src/assets/conf/
 
deploy_service2 comp
add_volume comp tools 600G /mnt/tools ReadWriteMany
add_volume comp comp-jobs-data 100G /opt/chipster/comp/jobs-data ReadWriteOnce

deploy_service toolbox
# needed for genome parameters
add_volume toolbox tools 600G /mnt/tools ReadWriteMany

# for tools-bin download
oc new-app base
add_volume base tools 600G /mnt/tools ReadWriteMany


set +e
set +x

echo '------------------------------------------------------------------------------'
echo '# 1) Download tools by running the following commands:'
echo '# login to the container'
echo 'oc rsh dc/base bash'
echo 'mkdir -p /mnt/tools/current'
echo 'cd /mnt/tools/current'
echo ''
echo '# Optionally, convert the tools.tar.gz to lz4 on the build or aux server'
echo 'cat tools.tar.gz | gunzip | lz4 > tools.tar.lz4 &'
echo ''
echo '# download and extract tool binaries'
echo 'curl http://vm0151.kaj.pouta.csc.fi/artefacts/create_tools_images/chipster-3.12.3/tools.tar.gz | tar -zx >> log.txt 2>&1 &'
echo 'or'
echo 'curl http://vm0151.kaj.pouta.csc.fi/artefacts/create_tools_images/chipster-3.12.3/tools.tar.lz4 | lz4 -d | tar -x >> log.txt 2>&1 &'
echo ''
echo '# logout from the container'
echo 'exit'
echo ''
echo '# delete the container'
echo 'oc delete dc base'
echo ''
echo '# Optionally, run the following in the container to fix dstat and other programs requiring a username'
echo 'bash /fix-username.bash'
echo '------------------------------------------------------------------------------'
echo '# 2) Configure user accounts in /opt/chipster-web-server/security/users on auth'
echo '------------------------------------------------------------------------------'