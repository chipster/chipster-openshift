
# exit on error
set -e

# e30K is base64 encoded {}
secret_template=$(cat << "EOF"
apiVersion: v1
kind: Secret
metadata:
    name: passwords
    labels:
        app: chipster
type: Opaque
data:
    values.yaml: e30K
EOF
)

echo "get old passwords from the server"
if ! secret_yaml=$(kubectl get secret passwords -o yaml); then
   secret_yaml="$secret_template" 
fi

values_json=$(echo "$secret_yaml" | yq r - --tojson | jq '.data."values.yaml"' -r | base64 -d)

#echo "$values_json"

for key in $(yq r values.yaml --tojson | jq '.deployments | keys[]' -r); do
    name=$(yq r values.yaml --tojson | jq .deployments.$key.name -r)
    old_password=$(echo "$values_json" | jq '.deployments."'$key'".password' -r)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
    else
        echo "generate password for $name"
        password=$(openssl rand -base64 30)
        values_json=$(echo $values_json | jq ".deployments.\"$key\".privateKey = \"$password\"")
    fi
done

for key in $(yq r values.yaml --tojson | jq '.databases | keys[]' -r); do
    name="$key"
    old_password=$(echo "$values_json" | jq '.databases."'$key'".password' -r)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
    else
        echo "generate password for $name"
        password=$(openssl rand -base64 30)
        values_json=$(echo $values_json | jq ".databases.\"$key\".privateKey = \"$password\"")
    fi
done

for key in $(yq r values.yaml --tojson | jq '.users | keys[]' -r); do
    name="$key"
    old_password=$(echo "$values_json" | jq '.users."'$key'".password' -r)
    if [[ $old_password != "null" ]]; then
        echo "use old password for $name:   $(echo "$old_password" | cut -c1-5)..."
    else
        echo "generate password for $name"
        password=$(diceware -w en)
        values_json=$(echo $values_json | jq ".users.\"$key\".privateKey = \"$password\"")
    fi
done

for key in $(yq r values.yaml --tojson | jq '.tokens | keys[]' -r); do
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

#echo "$values_json"

echo "update to server"

echo "$secret_yaml" | yq r - --tojson | jq ".data.\"values.yaml\" = \"$(echo "$values_json" | base64)\"" \
    | kubectl apply -f -