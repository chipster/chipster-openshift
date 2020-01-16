for d in $(sudo kubectl get deployment -o name); do 
    sudo kubectl rollout restart $d
done