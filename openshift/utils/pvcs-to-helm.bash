#!/bin/bash

namespace="$(oc project -q)"

for pvc in $(oc get pvc -o name | cut -d "/" -f 2 | grep -v postgres); do
    echo $pvc
    oc get pvc $pvc -o json \
        | jq '.metadata.labels."app.kubernetes.io/managed-by"="Helm"' \
        | jq '.metadata.annotations."meta.helm.sh/release-name"="chipster"' \
        | jq '.metadata.annotations."helm.sh/resource-policy"="keep"' \
        | jq '.metadata.annotations."meta.helm.sh/release-namespace"="'$namespace'"' | oc apply -f -
done

# db volumes are not managed by helm at the moment, but let's add this anyway for safety's sake
for pvc in $(oc get pvc -o name | cut -d "/" -f 2 | grep postgres); do
    echo $pvc
    oc get pvc $pvc -o json \
        | jq '.metadata.annotations."helm.sh/resource-policy"="keep"' \
        | oc apply -f -
done