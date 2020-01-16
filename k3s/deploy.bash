sudo helm uninstall chipster
sudo kubectl delete pvc tools-bin-chipster-3.15.6-temp

sudo kubectl get secret passwords -o json | jq .data.passwords -r | base64 -d \
    | sudo helm install chipster helm/chipster -f values.yaml -f - "$@"
