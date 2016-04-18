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
      storage: 249G
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
        - name: volume-sjrx2
          persistentVolumeClaim:
            claimName: tmp
      containers:
      - name: download
        image: 172.30.1.144:5000/chipster/base
        # basically just "curl URL | tar -zx", but with some tweaks to get realtime output from curl:
        # - curl outputs to a named pipe so that it will not suppress the status updates to stderr
        # - redirect stderr to stdout for easier editing
        # - flush output buffer after each line (stdbuf -oL)
        # - curl prints a carriage return after each status line. Replace it with a new line character
        #command: ["bash", "-c", "df -h && cd /opt/chipster/tools && mkfifo /tmp/pipe && tar -zxf /tmp/pipe & curl '$TOOLS_URL' -o /tmp/pipe 2>&1 | stdbuf -oL tr '\''\r'\'' '\''\n'\''"]
        command: ["bash", "-c", "df -h && curl '$TOOLS_URL' -o /opt/chipster/tmp/tools.tar.gz 2>&1 | stdbuf -oL tr '\''\r'\'' '\''\n'\'' && cd /opt/chipster/tools && cat /opt/chipster/tmp/tools.tar.gz | tar -zx"]
        volumeMounts:
           - name: volume-sjrxr
             mountPath: /opt/chipster/tools
           - name: volume-sjrx2
             mountPath: /opt/chipster/tmp             
      restartPolicy: Never
' | oc create -f -

oc set volume dc/comp --add -t pvc --mount-path /opt/chipster/tools --claim-name tool-binaries

