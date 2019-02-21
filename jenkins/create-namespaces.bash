#!/bin/bash

name="$1"
project="chipster-$name"

oc create project $project
oc create sa jenkins
oc policy add-role-to-user edit system:serviceaccount:$project:jenkins
token_secret="$(oc get -o json sa jenkins | jq .secrets[].name -r | grep token)"
token="$(oc get -o json secret $token_secret | jq .data.token -r | base64 --decode)"

bash dev/add_jenkins_credential.bash OPENSHIFT_PROJECT $project
bash dev/add_jenkins_credential.bash OPENSHIFT_TOKEN $token
