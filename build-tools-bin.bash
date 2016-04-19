#!/bin/bash

DEPS="R-3.0.2"
oc new-app --name tools-bin base~https://github.com/chipster/chipster-openshift.git \
--context-dir build-tools-bin/$DEPS --allow-missing-imagestream-tags --strategy=docker \
&& oc delete dc/tools-bin

echo '
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: artefacts
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 4G
' | oc create -f -


JOB_NAME="build-tools-bin"
BUILD_FILE="build-tools-bin/R-3.0.2.bash"
CMD="$(cat $BUILD_FILE | python -c 'import json,sys;str=sys.stdin.read();print(json.dumps(str))')"
echo "$CMD"
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
                        "image": "172.30.1.144:5000/chipster/base",
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

