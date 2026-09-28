# Install or upgrade Chipster to K3s
#
# Assumes that passwords are stored in a seccret "passwords" in K3s

# "helm upgrade --install" should do this, but -f option didn't work on the first run
if helm status chipster > /dev/null 2> /dev/null; then
    # One-time migration (GHSA-3j6x-m3jw-r5mg): the bash-job-scheduler RoleBinding
    # moved from ClusterRole "edit" to a minimal namespaced Role. A RoleBinding's
    # roleRef is immutable, so an in-place "helm upgrade" fails unless the old
    # binding is deleted first. Guarded so it only fires on the old binding and is
    # safe to run on every upgrade.
    if [ "$(kubectl get rolebinding bash-job-scheduler-rb -o jsonpath='{.roleRef.name}' 2>/dev/null)" = "edit" ]; then
        echo "Removing obsolete bash-job-scheduler-rb (bound to ClusterRole/edit) before upgrade"
        kubectl delete rolebinding bash-job-scheduler-rb
    fi
    kubectl get secret passwords -o json | jq '.data."values.yaml"' -r | base64 -d \
        | helm upgrade chipster helm/chipster -f - "$@"
else
    kubectl get secret passwords -o json | jq '.data."values.yaml"' -r | base64 -d \
        | helm install chipster helm/chipster -f - "$@"
fi