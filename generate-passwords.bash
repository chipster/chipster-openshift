#!/bin/bash

source scripts/utils.bash
set -e

subproject="$1"

if [ -z $subproject ]; then
  secret_name="passwords"
else
  secret_name="passwords-$subproject"
fi

echo "Generate passwords"
echo

password_secret='{
    "kind": "List",
    "apiVersion": "v1",
    "metadata": {},
    "items": [
        {
            "kind": "Secret",
            "apiVersion": "v1",
            "metadata": {
                "name": "'$secret_name'"
            },
            "data": {
            },
            "type": "Opaque"
        }
    ]
}'

function add_password {
  secret="$1"
  key="$2"
  value="$3"
  encoded_value="$(echo $value | base64)"
  
  echo "$secret" | jq .items[0].data.\"$key\"=\"$encoded_value\"  
}
  
authenticated_services=$(cat ../chipster-web-server/src/main/resources/chipster-defaults.yaml | grep ^service-password- | cut -d : -f 1 | sed s/service-password-//)

keys=""

for service in $authenticated_services; do
  keys+="service-password-$service"$'\n'
done

keys+="auth-db-password"$'\n'
keys+="session-db-db-password"$'\n'
keys+="job-history-db-password"$'\n'

for key in $keys; do
  password_secret="$(add_password "$password_secret" "$key" "$(generate_password)")"
done

echo "$password_secret" | oc apply -f -