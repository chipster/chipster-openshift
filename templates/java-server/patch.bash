#!/bin/bash

source scripts/utils.bash

template_dir="$1"
PROJECT="$2"
DOMAIN="$3"

patch_kind_and_name $template_dir/auth-dc.yaml DeploymentConfig auth "
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster-web-server/security
  spec.template.spec.containers[0].volumeMounts[2].name: security 
  spec.template.spec.volumes[2].name: security
  spec.template.spec.volumes[2].persistentVolumeClaim.claimName: auth-security
" false

patch_kind_and_name $template_dir/backup-dc.yaml DeploymentConfig backup "
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster-web-server/db-backups
  spec.template.spec.containers[0].volumeMounts[2].name: db-backups 
  spec.template.spec.volumes[2].name: db-backups
  spec.template.spec.volumes[2].persistentVolumeClaim.claimName: db-backups
" false
          
if false; then
patch_kind_and_name $template_dir/comp-mylly-dc.yaml DeploymentConfig comp-mylly "
  spec.template.spec.containers[0].resources.limits.cpu: 1900m
  spec.template.spec.containers[0].resources.limits.memory: 7900Mi
  spec.template.spec.containers[0].resources.requests.cpu: 1000m
  spec.template.spec.containers[0].resources.requests.memory: 4000Mi
  spec.template.spec.containers[0].volumeMounts[0].mountPath: /opt/chipster/comp/logs
  spec.template.spec.containers[0].volumeMounts[1].mountPath: /opt/chipster/comp/conf
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster/comp/jobs-data
  spec.template.spec.containers[0].volumeMounts[2].name: jobs-data
  spec.template.spec.containers[0].volumeMounts[3].mountPath: /appl
  spec.template.spec.containers[0].volumeMounts[3].name: tools-bin 
  spec.template.spec.volumes[2].name: jobs-data
  spec.template.spec.volumes[2].persistentVolumeClaim.claimName: comp-jobs-data-mylly
  spec.template.spec.volumes[3].name: tools-bin
  spec.template.spec.volumes[3].persistentVolumeClaim.claimName: tools-bin-mylly
" false
fi

patch_kind_and_name $template_dir/comp-dc.yaml DeploymentConfig comp "
  spec.template.spec.containers[0].resources.limits.cpu: 1900m
  spec.template.spec.containers[0].resources.limits.memory: 7900Mi
  spec.template.spec.containers[0].resources.requests.cpu: 1000m
  spec.template.spec.containers[0].resources.requests.memory: 4000Mi
  spec.template.spec.containers[0].volumeMounts[0].mountPath: /opt/chipster/comp/logs
  spec.template.spec.containers[0].volumeMounts[1].mountPath: /opt/chipster/comp/conf  
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster/comp/jobs-data
  spec.template.spec.containers[0].volumeMounts[2].name: jobs-data
  spec.template.spec.containers[0].volumeMounts[3].mountPath: /mnt/tools
  spec.template.spec.containers[0].volumeMounts[3].name: tools-bin
  spec.template.spec.volumes[2].name: jobs-data
  spec.template.spec.volumes[2].persistentVolumeClaim.claimName: comp-jobs-data
  spec.template.spec.volumes[3].name: tools-bin
  spec.template.spec.volumes[3].persistentVolumeClaim.claimName: tools-bin
" false

patch_kind_and_name $template_dir/file-broker-dc.yaml DeploymentConfig file-broker "
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster-web-server/storage
  spec.template.spec.containers[0].volumeMounts[2].name: storage
  spec.template.spec.volumes[2].name: storage
  spec.template.spec.volumes[2].persistentVolumeClaim.claimName: file-broker-storage
" false

patch_kind_and_name $template_dir/session-db-dc.yaml DeploymentConfig session-db "
  spec.template.spec.containers[0].ports[2].name: events
  spec.template.spec.containers[0].ports[2].containerPort: 8005  
" false

patch_kind_and_name $template_dir/toolbox-dc.yaml DeploymentConfig toolbox "
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /mnt/tools
  spec.template.spec.containers[0].volumeMounts[2].name: tools-bin
  spec.template.spec.volumes[2].name: tools-bin
  spec.template.spec.volumes[2].persistentVolumeClaim.claimName: tools-bin
" false

patch_kind_and_name $template_dir/web-server-dc.yaml DeploymentConfig web-server "
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster-web/src/assets/conf
  spec.template.spec.containers[0].volumeMounts[2].name: app-conf
  spec.template.spec.volumes[2].name: app-conf
  spec.template.spec.volumes[2].secret.secretName: web-server-app-conf
" false

patch_kind_and_name $template_dir/web-server-api-route.yaml Route web-server "
  spec.host: $PROJECT.$DOMAIN
" false
