# Generate passwords and store them in a Kubernetes secret
# 
# The Helm values.json file is iterated to check which passwords are needed.
# Passswords that are already stored are preserved. New or missing
# passwords are generated.
#
# The passwords are stored in the same format with the values.json file,
# allowing it to be passed directly to the Helm deployemnt.

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

values_json=$(echo "$secret_json" | jq '.data."values.json"' -r | base64 -d)

default_values_yaml_path="helm/chipster/values.yaml"

#echo "$values_json"

for key in $(yq e $default_values_yaml_path -o=json | jq '.deployments | keys[]' -r); do
    name=$(yq e $default_values_yaml_path -o=json | jq .deployments.$key.name -r)

    old_password=$(echo "$values_json" | jq '.deployments."'$key'".password' -r)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
    else
        echo "generate password for $name"
        password=$(openssl rand -base64 30)
        values_json=$(echo $values_json | jq ".deployments.\"$key\".password = \"$password\"")
    fi
done

# generate password for the monitoring account to replace default password
for key in "monitoring"; do
    name="$key"

    old_password=$(echo "$values_json" | jq '.serviceAccounts."'$key'".password' -r)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
    else
        echo "generate password for $name"
        password=$(openssl rand -base64 30)
        values_json=$(echo $values_json | jq ".serviceAccounts.\"$key\".password = \"$password\"")
    fi
done

for key in $(yq e $default_values_yaml_path -o=json | jq '.db | keys[]' -r); do
    name="$key"
    old_password=$(echo "$values_json" | jq .db.$key.password -r)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
    else
        echo "generate password for $name"
        password=$(openssl rand -base64 30)
        values_json=$(echo $values_json | jq ".db.$key.password = \"$password\"")
    fi
done

for key in $(yq e $default_values_yaml_path -o=json | jq '.tokens | keys[]' -r); do
    name="$key"    
    old_password=$(echo "$values_json" | jq '.tokens."'$key'".privateKey' -r)
    if [[ $old_password != "null" ]]; then
        echo "use old key for $name:   $(echo "$old_password" | head -n 1 | cut -c1-20)..."
    else
        echo "generate key for $name"
        password=$(openssl ecparam -genkey -name secp521r1 -noout)
        values_json=$(echo $values_json | jq ".tokens.\"$key\".privateKey = \"$password\"")
    fi
done

# echo "$values_json"

echo "update to server"

echo "$secret_json" | jq ".data.\"values.json\" = \"$(echo "$values_json" | base64)\"" \
    | kubectl apply -f -