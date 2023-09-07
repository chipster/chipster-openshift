#!/bin/bash

# >&2 ls */*
# >&2 pwd
# >&2 echo kustomize_dir: $CHIPSTER_KUSTOMIZE_DIR

# write helm output to the base
cat > base/helm-output.yaml

>&2 echo "** Kustomize"

oc kustomize $CHIPSTER_KUSTOMIZE_DIR
