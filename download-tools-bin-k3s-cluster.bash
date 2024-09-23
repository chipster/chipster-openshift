#!/bin/bash

set -e

command -v yq >/dev/null 2>&1 || { echo >&2 "I require yq but it's not installed.  Aborting."; exit 1; }

source scripts/utils.bash

tools_bin_version="$1"
tools_bin_size="$2"

if [ -z $tools_bin_version ]; then
  echo "Usage:   bash download-tools-bin.bash TOOLS_BIN_VERSION TOOLS_BIN_SIZE"
  echo "Example: bash download-tools-bin.bash chipster-3.15.6 550Gi"
  echo ""
  echo "Create an OpenShift job for downloading the specified tools-bin version from the object storage and follow its output."
  echo ""
  exit 1
fi


pvc_name="tools-bin-$tools_bin_version"

if kubectl get pvc $pvc_name; then
  echo "$pvc_name exists already"
  exit 1
fi

cat <<EOF | kubectl apply -f -
apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata:
  annotations:
    volume.beta.kubernetes.io/storage-class: nfs-1
  name: ${pvc_name}    
spec:
  accessModes:
    - "ReadWriteOnce"
  resources:
    requests:
      storage: ${tools_bin_size}
EOF
	
temp_pvc="${pvc_name}-temp"
while kubectl get pvc $temp_pvc; do
  kubectl delete pvc $temp_pvc
  sleep 1
done

cat <<EOF | kubectl apply -f -
apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata:
  annotations:
    volume.beta.kubernetes.io/storage-class: local-path
  name: ${temp_pvc}    
spec:
  accessModes:
    - "ReadWriteOnce"
  resources:
    requests:
      storage: 400Gi
EOF

name=download-tools-bin-bash-job

cat <<EOF | yq | jq .spec.template.spec.containers[0].command[2]="$(cat openshift/jobs/download-tools-bin.bash | jq -s -R .)" | kubectl apply -f -
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
        image: image-registry.apps.2.rahti.csc.fi/chipster-images/base
        command: ["bash", "-c", ""]
        resources:
          limits:
            cpu: 1
            memory: 4Gi
          requests:
            cpu: 1
            memory: 4Gi          
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
      nodeSelector:
        role: user
      tolerations:
        - effect: NoSchedule
          key: role
          value: user
EOF



#TODO how to run this after the job has finished?
#oc delete pvc $temp_pvc
