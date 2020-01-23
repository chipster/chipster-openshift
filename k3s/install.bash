kubectl get secret passwords -o json | jq '.data."values.yaml"' -r | base64 -d \
    | helm upgrade --install chipster helm/chipster -f - "$@"
