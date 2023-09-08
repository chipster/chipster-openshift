#!/bin/bash

# >&2 ls */*
# >&2 pwd
# >&2 echo kustomize_dir: $CHIPSTER_KUSTOMIZE_DIR

# write helm output to the base
cat > base/helm-output.yaml

>&2 echo "** Kustomize"

oc kustomize $CHIPSTER_KUSTOMIZE_DIR

# there should be no need to delete the base/helm-output.yaml, because deploy.bash is running 
# this in a temporary directory and should delete the whole directory soon
