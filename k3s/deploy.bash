# Install or upgrade Chipster to K3s
#
# Assumes that passwords are stored in a seccret "passwords" in K3s

# "helm upgrade --install" should do this, but -f option didn't work on the first run
if helm status chipster > /dev/null 2> /dev/null; then
    kubectl get secret passwords -o json | jq '.data."values.yaml"' -r | base64 -d \
        | helm upgrade chipster helm/chipster -f - "$@"
else
    kubectl get secret passwords -o json | jq '.data."values.yaml"' -r | base64 -d \
        | helm install chipster helm/chipster -f - "$@"
fi