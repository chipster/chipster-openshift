#!/bin/bash

set -e

source scripts/utils.bash

job="$1"
tools_bin_version="$2"
temp_pvc="$3"

if [ -z $tools_bin_version ]; then
  echo "Usage: bash run-job-with-tools-bin.bash BASH_JOB TOOLS_BIN_VERSION"
  exit 1
fi

name=$(basename $job .bash)-bash-job

if kubectl get job $name > /dev/null 2>&1; then
  kubectl delete job $name  
  #TODO wait until the job isn't Running anymore
fi

cat <<EOF | yq e -o json - | jq .spec.template.spec.containers[0].command[2]="$(cat $job | jq -s -R .)" | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ${name}
spec:
  parallelism: 1    
  completions: 1    
  template:         
    metadata:
      name: ${name}
    spec:
      containers:
      - env:
        - name: TOOLS_BIN_VERSION
          value: ${tools_bin_version}
        name: ${name}
        image: docker-registry.rahti.csc.fi/chipster-images-release/base
        command: ["bash", "-c", ""]
        resources:
          limits:
            cpu: 2
            memory: 8Gi
          requests:
            cpu: 2
            memory: 8Gi          
        volumeMounts:        
        - mountPath: /mnt/tools
          name: tools-bin
        - mountPath: /mnt/temp
          name: temp
      volumes:
      - name: tools-bin
        persistentVolumeClaim:
          claimName: tools-bin-${tools_bin_version}
      - name: temp
        persistentVolumeClaim:
          claimName: ${temp_pvc}
        #emptyDir: {}
      restartPolicy: OnFailure
EOF
