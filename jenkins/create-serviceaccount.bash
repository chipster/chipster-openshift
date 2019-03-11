#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Usage: bash create-serviceaccount.bash NAME [ -q ]"
  exit 1
fi

if [ "$2" == "-q" ]; then
  quiet="true"
fi

name="$1"

project="$(oc project -q)"

out="$(oc create sa $name; oc policy add-role-to-user edit system:serviceaccount:$project:$name)"

token_secret="$(oc get -o json sa $name | jq .secrets[].name -r | grep token)"
token="$(oc get -o json secret $token_secret | jq .data.token -r | base64 --decode)"

if [ "$quiet" != "true" ]; then
  echo "Creating serviceaccount $name in project $project"
  echo "$out"
  echo "Account created. Token:"
fi

echo $token
