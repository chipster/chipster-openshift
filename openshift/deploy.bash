#!/bin/bash

set -e

helm template helm-instance-name helm/chipster > kustomize/base/helm-output.yaml; oc apply -k kustomize/overlays/low-pod-quota