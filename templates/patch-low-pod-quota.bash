#!/bin/bash

source scripts/utils.bash

template_dir="$1"
subproject_postfix="$2"

patch_kind_and_name $template_dir/backup.yaml DeploymentConfig backup$subproject_postfix "
  spec.replicas: 0
" false

patch_kind_and_name $template_dir/job-history.yaml DeploymentConfig job-history$subproject_postfix "
  spec.replicas: 0
" false

patch_kind_and_name $template_dir/monitoring.yaml DeploymentConfig influxdb$subproject_postfix "
  spec.replicas: 0
" false

patch_kind_and_name $template_dir/monitoring.yaml DeploymentConfig grafana$subproject_postfix "
  spec.replicas: 0
" false

patch_kind_and_name $template_dir/logging.yaml DeploymentConfig logstash$subproject_postfix "
  spec.replicas: 0
" false
