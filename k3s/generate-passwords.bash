# Generate passwords and store them in a Kubernetes secret
# 
# The Helm values.yaml file is iterated to check which passwords are needed.
# Passswords that are already stored are preserved. New or missing
# passwords are generated.
#
# The passwords are stored in the same format with the values.yaml file,
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
    "values.yaml": "e30K"
  }
}
EOF
)

echo "get old passwords from the server"
if ! secret_json=$(kubectl get secret passwords -o json); then
   secret_json="$secret_template" 
fi

values_json=$(echo "$secret_json" | jq '.data."values.yaml"' -r | base64 -d)

default_values_yaml_path="helm/chipster/values.yaml"

#echo "$values_json"

for key in $(yq e $default_values_yaml_path --tojson | jq '.deployments | keys[]' -r); do
    name=$(yq e $default_values_yaml_path --tojson | jq .deployments.$key.name -r)
    old_password=$(echo "$values_json" | jq '.deployments."'$key'".password' -r)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
    else
        echo "generate password for $name"
        password=$(openssl rand -base64 30)
        values_json=$(echo $values_json | jq ".deployments.\"$key\".password = \"$password\"")
    fi
done

for key in $(yq e $default_values_yaml_path --tojson | jq '.databases | keys[]' -r); do
    name="$key"
    passwordKey=$(yq e $default_values_yaml_path --tojson | jq .databases.$key.passwordKey -r)
    old_password=$(echo "$values_json" | jq .$passwordKey -r)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
    else
        echo "generate password for $name"
        password=$(openssl rand -base64 30)
        values_json=$(echo $values_json | jq ".$passwordKey = \"$password\"")
    fi
done

for key in $(yq e $default_values_yaml_path --tojson | jq '.users | keys[]' -r); do
    name="$key"
    old_password=$(echo "$values_json" | jq '.users."'$key'".password' -r)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
    else
        echo "generate password for $name"
        password=$(diceware -w en)
        values_json=$(echo $values_json | jq ".users.\"$key\".password = \"$password\"")
    fi
done

for key in $(yq e $default_values_yaml_path --tojson | jq '.tokens | keys[]' -r); do
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

# # create kubeconfig
ip=$(ip route get 1 | awk '{print $(NF-2);exit}')

echo "Chipster will use ip address $ip to start jobs in K3s"
kubeconfig_json=$(kubectl config view --raw -o json | jq .clusters[0].cluster.server=\"https://$ip:6443\" | jq -s -R .)

values_json=$(echo $values_json | jq ".kubeconfig=$kubeconfig_json")

# for debugging, delete kubeconfig
#values_json=$(echo $values_json | jq 'del(.kubeconfig)')

#echo "$values_json"

echo "update to server"

echo "$secret_json" | jq ".data.\"values.yaml\" = \"$(echo "$values_json" | base64)\"" \
    | kubectl apply -f -

