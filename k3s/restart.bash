#!/bin/bash

# Restart all Chipster services
#
# Restarts all Kubernetes deployments to be more precise. Only Chipster 
# services are Kubernetes deployments at the moment (Postgreses are statefulsets), 
# but maybe we should get the current list of deployments form the 
# Helm values.yaml file to be more explicit.

for d in $(kubectl get deployment -o name); do 
    kubectl rollout restart $d
done