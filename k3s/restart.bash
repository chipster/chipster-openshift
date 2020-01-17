for d in $(kubectl get deployment -o name); do 
    kubectl rollout restart $d
done