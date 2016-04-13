#!/bin/bash


if [ $# -eq 0 ]
  then
    echo "Usgae: deploy.bash PROJECT [CHIPSTER_BRANCH, SERVER_BRANCH, CLIENT_BRANCH, TOOLS_BRANCH]"
    exit 0
fi

# check if login is needed
oc get projects > /dev/null

if [ $? -eq 1 ]
then
  oc login
fi

oc project "$1"

if [ $? -eq 1 ]
then
  oc new-project "$1"
fi

if [[ $(oc project -q) != "$1" ]]
then
  echo "failed to create the project"
  exit 1
fi 

if [[ $(oc get all) ]]
then
  echo "The project is not empty"
  exit 1
fi 

if [ -z "$2" ]
then
  CHIPSTER_BRANCH="$2"
else
  CHIPSTER_BRANCH="openshift"
fi

if [ -z "$3" ]
then
  SERVER_BRANCH="$3"
else
  SERVER_BRANCH="openshift"
fi

if [ -z "$4" ]
then
  CLIENT_BRANCH="$4"
else
  CLIENT_BRANCH="openshift"
fi

if [ -z "$5" ]
then
  TOOLS_BRANCH="$5"
else
  TOOLS_BRANCH="openshift"
fi

set -e
set -x

# create image streams

oc new-app --name base https://github.com/chipster/chipster-openshift.git \
--context-dir dockerfiles/base \
&& oc delete dc/base

oc new-app --name chipster-jms base~https://github.com/chipster/chipster-openshift.git \
--context-dir dockerfiles/chipster-jms --allow-missing-imagestream-tags --strategy=docker \
--env CHIPSTER_BRANCH="$CHIPSTER_BRANCH" \
&& oc delete dc/chipster-jms

oc new-app --name chipster-web-server chipster-jms~https://github.com/chipster/chipster-openshift.git \
--context-dir dockerfiles/chipster-web-server --allow-missing-imagestream-tags --strategy=docker \
--env SERVER_BRANCH="$SERVER_BRANCH" \
&& oc delete dc/chipster-web-server

oc new-app --name chipster-web chipster-web-server~https://github.com/chipster/chipster-openshift.git \
--context-dir dockerfiles/chipster-web --allow-missing-imagestream-tags --strategy=docker \
--env CLIENT_BRANCH="$CLIENT_BRANCH" \
&& oc delete dc/chipster-web

oc new-app --name chipster-tools chipster-web-server~https://github.com/chipster/chipster-openshift.git \
--context-dir dockerfiles/chipster-tools --allow-missing-imagestream-tags --strategy=docker \
--env TOOLS_BRANCH="$TOOLS_BRANCH" \
&& oc delete dc/chipster-tools

# deploy

oc new-app --name auth --image-stream chipster-web-server \
--env JAVA_CLASS=fi.csc.chipster.auth.AuthenticationService \
--env authentication_service_bind=http://0.0.0.0:8080/ \
--allow-missing-imagestream-tags \
&& oc expose dc/auth --port=8080 && oc expose service auth

oc new-app --name service-locator --image-stream chipster-web-server \
--env JAVA_CLASS=fi.csc.chipster.servicelocator.ServiceLocator \
--env service_locator_bind=http://0.0.0.0:8080/ \
--env authentication_service=http://auth:8080/ \
--env session_db=http://session-db:8080/ \
--env session_db_events=ws://session-db:8081/ \
--env file_broker=http://file-broker:8080/ \
--env scheduler=ws://scheduler:8080/ \
--env toolbox_url=http://toolbox:8080/ \
--allow-missing-imagestream-tags && oc expose dc/service-locator --port=8080

oc new-app --name session-db --image-stream chipster-web-server \
--env JAVA_CLASS=fi.csc.chipster.sessiondb.SessionDb \
--env session_db_bind=http://0.0.0.0:8080/ \
--env session_db_events_bind=ws://0.0.0.0:8081/	\
--env service_locator=http://service-locator:8080/ \
--allow-missing-imagestream-tags \
&& oc expose dc/session-db --name=session-db --port=8080

oc patch service session-db -p '{
	"spec": {
        "ports": [
            {
                "name": "rest",
                "protocol": "TCP",
                "port": 8080,
                "targetPort": 8080
            },
            {
                "name": "websocket",
                "protocol": "TCP",
                "port": 8081,
                "targetPort": 8081
            }
        ]
	}
}'

oc expose service session-db --name session-db && oc expose service session-db --name session-db-events

oc patch route session-db-events -p '{
    "spec": {
        "port": {
            "targetPort": "websocket"
        }
    }
}'

oc new-app --name file-broker --image-stream chipster-web-server \
--env JAVA_CLASS=fi.csc.chipster.filebroker.FileBroker \
--env file_broker_bind=http://0.0.0.0:8080/ \
--env service_locator=http://service-locator:8080/ \
--allow-missing-imagestream-tags \
&& oc expose dc/file-broker --port=8080 && oc expose service file-broker

oc new-app --name scheduler --image-stream chipster-web-server \
--env JAVA_CLASS=fi.csc.chipster.scheduler.Scheduler \
--env scheduler_bind=ws://0.0.0.0:8080/ \
--env service_locator=http://service-locator:8080/ \
--allow-missing-imagestream-tags && oc expose dc/scheduler --port=8080

oc new-app --name toolbox --image-stream chipster-tools \
--env JAVA_CLASS=fi.csc.chipster.toolbox.ToolboxService \
--env toolbox_bind_url=http://0.0.0.0:8080/ \
--env service_locator=http://service-locator:8080/ \
--allow-missing-imagestream-tags \
&& oc expose dc/toolbox --port=8080 && oc expose service toolbox

oc new-app --name comp --image-stream chipster-tools \
--env JAVA_CLASS=fi.csc.chipster.comp.RestCompServer \
--env service_locator=http://service-locator:8080/ \
--allow-missing-imagestream-tags

oc new-app --name web --image-stream chipster-web \
--env web_bind=http://0.0.0.0:8080/ \
--allow-missing-imagestream-tags \
&& oc expose dc/web --port=8080 && oc expose service web 

echo '
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: tool-binaries
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 200G
' | oc create -f -

#oc delete job download
TOOLS_URL="http://bio.nic.funet.fi/pub/sci/molbio/chipster/dist/virtual_machines/3.7.2/tools/tools.tar.gz"
echo '
apiVersion: extensions/v1beta1
kind: Job
metadata:
  name: download
spec:
  selector:         
    matchLabels:
      app: download
  parallelism: 1    
  completions: 1    
  template:         
    metadata:
      name: download
      labels:
        app: download
    spec:
      volumes:
        - name: volume-sjrxr
          persistentVolumeClaim:
            claimName: tool-binaries
      containers:
      - name: download
        image: 172.30.1.144:5000/chipster/base
        command: ["bash", "-c", "df -h && cd /opt/chipster/tools && curl '$TOOLS_URL' | tar -zx"]
        volumeMounts:
           - name: volume-sjrxr
             mountPath: /opt/chipster/tools
      restartPolicy: Never
' | oc create -f -

oc set volume dc/comp --add -t pvc --mount-path /opt/chipster/tools --claim-name tool-binaries


