#!/bin/bash

set -e

name="$1"
type="$2"
file_or_value="$3"
	
json_template='{
	"config": {
		"stapler-class": "org.jenkinsci.plugins.configfiles.custom.CustomConfig", 
		"id": "'$name'", 
		"providerId": "org.jenkinsci.plugins.configfiles.custom.CustomConfig", 
		"name": "'$name'", 
		"comment": "", 
		"content": "'$value'"
	}
}'

if [ "$type" == "--file" ]; then
  value="$(cat $file_or_value)"
elif [ "$type" == "--string" ]; then
  value="$file_or_value"
else
  echo "Unknown type, only --file or --string allowed: $type"
  exit 1
fi

json_encoded_value="$(echo "$value" | jq -s -R . )"
json="$(echo "$json_template" \
  | jq .config.content="$json_encoded_value")"

curl -X POST $JENKINS_HOST/configfiles/saveConfig --user $JENKINS_USER:$JENKINS_TOKEN \
	--data-urlencode json="$json"

#curl -X POST $JENKINS_HOST/configfiles/removeConfig?id=test1 --user $JENKINS_USER:$JENKINS_TOKEN
