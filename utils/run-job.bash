#!/bin/bash

set -e

if [ $# -eq 0 ]
  then
    echo "Usgae: run-job.bash JOB_NAME BASH_SCRIPT [IMAGE]"
    exit 0
fi

if [ -z "$3" ]
then
  IMAGE="$3"
else
  IMAGE="base"
fi

JOB_NAME="$1"
CMD="$(cat "$2" | python -c 'import json,sys;str=sys.stdin.read();print(json.dumps(str))')"
oc delete job $JOB_NAME
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
                    }
                ],
                "containers": [
                    {
                        "name": "'$JOB_NAME'",
                        "image": "172.30.1.144:5000/chipster/'$IMAGE'",
                        "command": [
                            "bash",
                            "-c",
                            ' > cmd1
                            
echo "$CMD" > cmd2

echo '
                        ],
                        "resources": {},
                        "volumeMounts": [
                            {
                                "name": "volume-sjrx3",
                                "mountPath": "/mnt/artefacts"
                            }
                        ],
                        "imagePullPolicy": "Always"
                    }
                ],
                "restartPolicy": "Never",
                "terminationGracePeriodSeconds": 1
            }
        }
    }
}' > cmd3
cat cmd1 cmd2 cmd3 | oc create -f -
rm cmd1 cmd2 cmd3

bash $(dirname "${BASH_SOURCE[0]}")/follow-logs.bash $JOB_NAME