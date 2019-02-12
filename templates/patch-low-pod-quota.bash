#!/bin/bash

source scripts/utils.bash

patch_kind_and_name $1/backup-dc.yaml DeploymentConfig backup "
  spec.replicas: 0
" false

patch_kind_and_name $1/job-history-dc.yaml DeploymentConfig job-history "
  spec.replicas: 0
" false

patch_kind_and_name $1/monitoring.yaml DeploymentConfig influxdb "
  spec.replicas: 0
" false

patch_kind_and_name $1/monitoring.yaml DeploymentConfig grafana "
  spec.replicas: 0
" false
