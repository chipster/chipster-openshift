#!/bin/bash

  key="$1"
  value="$2"
  
  json_template='{
    "": "0",
    "credentials": {
      "scope": "GLOBAL",
      "id": "",
      "secret": "",
      "description": "",
      "$class": "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl"
    }
  }'
  
  json_encoded_value="$(echo "$value" | jq -s -R . )"
  json="$(echo "$json_template" \
    | jq .credentials.id=\"$key\" \
    | jq .credentials.secret="$json_encoded_value")"
   
  curl -X POST --user $JENKINS_USER:$JENKINS_TOKEN "$JENKINS_HOST/credentials/store/system/domain/_/createCredentials" \
  --data-urlencode json="$json"
