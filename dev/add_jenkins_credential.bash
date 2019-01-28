#!/bin/bash

  key="$1"
  value="$2"
   
  curl -X POST --user $JENKINS_USER:$JENKINS_TOKEN 'https://jenkins-chipster-jenkins.rahtiapp.fi/credentials/store/system/domain/_/createCredentials' \
  --data-urlencode 'json={
    "": "0",
    "credentials": {
      "scope": "GLOBAL",
      "id": "'"$key"'",
      "secret": "'"$value"'",
      "description": "",
      "$class": "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl"
    }
  }'
