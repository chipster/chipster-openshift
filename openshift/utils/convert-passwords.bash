# Old Chipster installation in OpenShift saved passwords directly in Secret
# key-value pairs, with keys like "service-password-auth". Convert it to values.yaml, which
# can directly be used in Helm

# exit on error
set -e

# e30K is base64 encoded {}
secret_template=$(cat << "EOF"
{
  "apiVersion": "v1",
  "kind": "Secret",
  "metadata": {
    "name": "passwords",
    "labels": {
      "app": "chipster"
    }
  },
  "type": "Opaque",
  "data": {
    "values.json": "e30K"
  }
}
EOF
)

echo "get old passwords from the server"
if ! secret_json=$(kubectl get secret passwords -o json); then
   secret_json="$secret_template" 
fi

if [ $(echo $secret_json | jq '.data."values.json"') == "null" ]; then
    echo "create an empty values.json"
    secret_json="$(echo $secret_json | jq '.data."values.json" = "'$(echo "{}" | base64)'"')"
fi

values_json=$(echo "$secret_json" | jq '.data."values.json"' -r | base64 -d)

default_values_yaml_path="../helm/chipster/values.yaml"

# echo "$values_json"

echo "convert service passwords"
for key in $(yq e $default_values_yaml_path -o=json | jq '.deployments | keys[]' -r); do
    echo "  $key"
    name=$(yq e $default_values_yaml_path -o=json | jq .deployments.$key.name -r)

    old_password=$(echo "$secret_json" | jq .data.\"service-password-$name\" -r | base64 -d)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
        values_json=$(echo $values_json | jq ".deployments.$key.password = \"$old_password\"")
        secret_json=$(echo $secret_json |  jq "del(.data.\"service-password-$name\")")
    else
        echo "password not found: $name"
    fi
done

echo "convert monitoring password"
for key in "monitoring"; do
    name="$key"

    old_password=$(echo "$secret_json" | jq .data.\"monitoring-password\" -r | base64 -d)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
        values_json=$(echo $values_json | jq ".serviceAccounts.monitoring.password = \"$old_password\"")
        secret_json=$(echo $secret_json |  jq "del(.data.\"monitoring-password\")")
    else
        echo "password not found: $name"
    fi
done

echo "convert database passwords"
for key in $(yq e $default_values_yaml_path -o=json | jq '.db | keys[]' -r); do
    echo "  $key"
    name=$(yq e $default_values_yaml_path -o=json | jq .db.$key.name -r)
    old_password=$(echo "$secret_json" | jq .data.\"$name-db-password\" -r | base64 -d)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
        values_json=$(echo $values_json | jq ".db.$key.password = \"$old_password\"")
        secret_json=$(echo $secret_json |  jq "del(.data.\"$name-db-password\")")
    else
        echo "password not found: $name"
    fi
done

echo "convert signing key"
for key in "auth"; do
    name="$key"    
    old_password=$(echo "$secret_json" | jq .data.\"jws-private-key-auth\" -r | base64 -d)
    if [[ $old_password != "null" ]]; then
        echo "use old key for $name:   $(echo "$old_password" | head -n 1 | cut -c1-20)..."
        values_json=$(echo $values_json | jq ".tokens.$key.privateKey = \"$old_password\"")
        secret_json=$(echo $secret_json |  jq "del(.data.\"jws-private-key-auth\")")
    else
        echo "key not found: $name"
    fi
done

# echo "$values_json"

echo "update to server"

echo "$secret_json" | jq ".data.\"values.json\" = \"$(echo "$values_json" | base64)\"" \
    | kubectl apply -f -