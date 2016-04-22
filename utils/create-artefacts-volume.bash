#!/bin/bash

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
      storage: 500G
' | oc create -f -