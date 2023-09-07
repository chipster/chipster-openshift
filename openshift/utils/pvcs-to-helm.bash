#!/bin/bash

namespace="$(oc project -q)"

for pvc in $(oc get pvc -o name | cut -d "/" -f 2); do
    echo $pvc
    oc get pvc $pvc -o json \
        | jq '.metadata.labels."app.kubernetes.io/managed-by"="Helm"' \
        | jq '.metadata.annotations."meta.helm.sh/release-name"="chipster"' \
        | jq '.metadata.annotations."meta.helm.sh/release-namespace"="'$namespace'"' | oc apply -f -
done
