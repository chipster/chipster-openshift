#!/bin/bash

set -e

EXIT_CODE=1

if [ $# -eq 0 ]
then
  echo "Usgae: run-job.bash BASH_SCRIPT IMAGE"
  exit 0
fi

if [ -z "$1" ]
then
  echo "BASH_SCRIPT parameter missing"
  exit 1
fi

BASH_SCRIPT="$1"
shift

if [ -z "$1" ]
then
  echo "IMAGE parameter missing"
  exit 1 
fi

IMAGE="$1"
shift

# generate valid job names from the script name by 
# - removing the path and file extension
# - changing uppercase letters to lowercase
# - replacing any special characters with dashes 
JOB_NAME=job-$(basename $BASH_SCRIPT .bash | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z|0-9]/-/g' )

if oc get job $JOB_NAME > /dev/null 2>&1 ; then
  oc delete job $JOB_NAME
fi

echo '
{
    "kind": "Job",
    "apiVersion": "extensions/v1beta1",
    "metadata": {
        "name": "'$JOB_NAME'"
    },
    "spec": {
        "parallelism": 1,
        "completions": 1,
        "selector": {
            "matchLabels": {
                "app": "'$JOB_NAME'"
            }
        },
        "template": {
            "metadata": {
                "name": "'$JOB_NAME'",
                "labels": {
                    "app": "'$JOB_NAME'"
                }
            },
            "spec": {
                "volumes": [
                    {
                        "name": "volume-sjrx3",
                        "persistentVolumeClaim": {
                            "claimName": "artefacts"
                        }
                    },
                    {
                        "name": "volume-empty-dir1",
                        "emptyDir": { }
                    }
                ],
                "containers": [
                    {
                        "name": "'$JOB_NAME'",
                        "image": "172.30.1.144:5000/chipster/'$IMAGE'",
                        "command": [
                            "sleep",
                            "inf"
                        ],
                        "resources": {},
                        "volumeMounts": [
                            {
                                "name": "volume-sjrx3",
                                "mountPath": "/mnt/artefacts"
                            },
                            {
                                "name": "volume-empty-dir1",
                                "mountPath": "/opt"
                            }
                        ],
                        "imagePullPolicy": "Always"
                    }
                ],
                "restartPolicy": "Never",
                "terminationGracePeriodSeconds": 30
            }
        }
    }
}' | oc create -f -


function get_running_pods {
  oc get pod -l app=$JOB_NAME | grep Running
}

until test $(get_running_pods | wc -l ) -eq 1 ; do
  echo "Waiting for pod"
  sleep 2
done

POD=$(get_running_pods | cut -d " " -f 1)

#echo "** Pod: $POD" 

until oc exec "$POD" cat /etc/issue ; do
  echo "Waiting for pod to be accessible"
  sleep 2
done

echo "** Copy scripts"
oc rsync . $POD:/tmp/job --exclude='.git' > /dev/null

# delete the job in the end to prevent failed jobs from restarting
function finish {
  oc delete job $JOB_NAME
  if [ $EXIT_CODE -eq 0 ] ; then 
    echo "JOB SUCCESSFUL ($EXIT_CODE)"
  else
    echo "JOB FAILED ($EXIT_CODE)"
  fi  
  exit $EXIT_CODE
}
trap finish EXIT

echo "** Run"
oc exec $POD -- bash -c "source /tmp/job/envs.bash && source /tmp/job/$BASH_SCRIPT $@"

EXIT_CODE=$?