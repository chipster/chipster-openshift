helm uninstall chipster

kubectl get secret passwords -o json | jq '.data."values.yaml"' -r | base64 -d \
    | helm install chipster helm/chipster -f values.yaml -f - "$@"
