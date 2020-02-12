#!/bin/bash

# Small utility for checking the content of the Kubernetes secret
#
# Shows the value of the Chipster configuration file "chipster.yaml" by default.

secret="$1"
key="${2:-chipster.yaml}"

if [ -z $secret ]; then
    echo "Usage: bash get-secret.bash SECRET [KEY]"
    exit 1
fi

kubectl get secret $secret -o json | jq .data.\"$key\" -r | base64 -d
