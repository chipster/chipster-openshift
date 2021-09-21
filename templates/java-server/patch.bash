#!/bin/bash

source scripts/utils.bash

template_dir="$1"
PROJECT="$2"
DOMAIN="$3"
tools_bin="$4"
subproject="$5"

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
fi

patch_kind_and_name $template_dir/auth.yaml DeploymentConfig auth$subproject_postfix "
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster/security
  spec.template.spec.containers[0].volumeMounts[2].name: security 
  spec.template.spec.volumes[2].name: security
  spec.template.spec.volumes[2].persistentVolumeClaim.claimName: auth-security$subproject_postfix
" false

patch_kind_and_name $template_dir/backup.yaml DeploymentConfig backup$subproject_postfix "
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster/db-backups
  spec.template.spec.containers[0].volumeMounts[2].name: db-backups 
  spec.template.spec.volumes[2].name: db-backups
  spec.template.spec.volumes[2].persistentVolumeClaim.claimName: db-backups$subproject_postfix
" false
          
# only if mylly was enabled
if [ -f $template_dir/comp-mylly.yaml ]; then
	patch_kind_and_name $template_dir/comp-mylly.yaml DeploymentConfig comp-mylly$subproject_postfix "
	  spec.template.spec.containers[0].resources.limits.cpu: 1600m
	  spec.template.spec.containers[0].resources.limits.memory: 7900Mi
	  spec.template.spec.containers[0].resources.requests.cpu: 1000m
	  spec.template.spec.containers[0].resources.requests.memory: 4000Mi
	  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster/jobs-data
	  spec.template.spec.containers[0].volumeMounts[2].name: jobs-data
	  spec.template.spec.containers[0].volumeMounts[3].mountPath: /appl
	  spec.template.spec.containers[0].volumeMounts[3].name: tools-bin
	  spec.template.spec.containers[0].volumeMounts[3].readOnly: true
	  spec.template.spec.volumes[2].name: jobs-data
	  spec.template.spec.volumes[2].emptyDir: {}
	  spec.template.spec.volumes[3].name: tools-bin
	  spec.template.spec.volumes[3].persistentVolumeClaim.claimName: tools-bin-mylly$subproject_postfix
	" false
fi

patch_kind_and_name $template_dir/comp.yaml DeploymentConfig comp$subproject_postfix "
  spec.template.spec.containers[0].resources.limits.cpu: 1600m
  spec.template.spec.containers[0].resources.limits.memory: 7900Mi
  spec.template.spec.containers[0].resources.requests.cpu: 1000m
  spec.template.spec.containers[0].resources.requests.memory: 4000Mi
  spec.template.spec.containers[0].volumeMounts[0].mountPath: /opt/chipster/comp/logs
  spec.template.spec.containers[0].volumeMounts[1].mountPath: /opt/chipster/comp/conf  
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster/comp/jobs-data
  spec.template.spec.containers[0].volumeMounts[2].name: jobs-data
  spec.template.spec.containers[0].volumeMounts[3].mountPath: /mnt/tools
  spec.template.spec.containers[0].volumeMounts[3].name: tools-bin
  spec.template.spec.containers[0].volumeMounts[3].readOnly: true
  spec.template.spec.volumes[2].name: jobs-data
  spec.template.spec.volumes[2].emptyDir: {}
  spec.template.spec.volumes[3].name: tools-bin
  spec.template.spec.volumes[3].persistentVolumeClaim.claimName: tools-bin-$tools_bin
" false

patch_kind_and_name $template_dir/comp-large.yaml DeploymentConfig comp-large$subproject_postfix "
  spec.template.spec.containers[0].resources.limits.cpu: 1600m
  spec.template.spec.containers[0].resources.limits.memory: 7900Mi
  spec.template.spec.containers[0].resources.requests.cpu: 1000m
  spec.template.spec.containers[0].resources.requests.memory: 4000Mi
  spec.template.spec.containers[0].volumeMounts[0].mountPath: /opt/chipster/comp/logs
  spec.template.spec.containers[0].volumeMounts[1].mountPath: /opt/chipster/comp/conf  
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster/comp/jobs-data
  spec.template.spec.containers[0].volumeMounts[2].name: jobs-data
  spec.template.spec.containers[0].volumeMounts[3].mountPath: /mnt/tools
  spec.template.spec.containers[0].volumeMounts[3].name: tools-bin
  spec.template.spec.containers[0].volumeMounts[3].readOnly: true
  spec.template.spec.volumes[2].name: jobs-data
  spec.template.spec.volumes[2].emptyDir: {}
  spec.template.spec.volumes[3].name: tools-bin
  spec.template.spec.volumes[3].persistentVolumeClaim.claimName: tools-bin-$tools_bin
" false

# patch_kind_and_name $template_dir/file-storage-single.yaml DeploymentConfig file-storage-single$subproject_postfix "
#   spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster/storage
#   spec.template.spec.containers[0].volumeMounts[2].name: storage
#   spec.template.spec.volumes[2].name: storage
#   spec.template.spec.volumes[2].persistentVolumeClaim.claimName: file-broker-storage$subproject_postfix
# " false

patch_kind_and_name $template_dir/session-db.yaml DeploymentConfig session-db$subproject_postfix "
  spec.template.spec.containers[0].ports[2].name: events
  spec.template.spec.containers[0].ports[2].containerPort: 8005  
" false

patch_kind_and_name $template_dir/toolbox.yaml DeploymentConfig toolbox$subproject_postfix "
  spec.template.spec.containers[0].volumeMounts[0].mountPath: /opt/chipster/toolbox/logs
  spec.template.spec.containers[0].volumeMounts[1].mountPath: /opt/chipster/toolbox/conf
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /mnt/tools
  spec.template.spec.containers[0].volumeMounts[2].name: tools-bin
  spec.template.spec.containers[0].volumeMounts[2].readOnly: true
  spec.template.spec.volumes[2].name: tools-bin
  spec.template.spec.volumes[2].persistentVolumeClaim.claimName: tools-bin-$tools_bin
" false

patch_kind_and_name $template_dir/web-server.yaml DeploymentConfig web-server$subproject_postfix "
  spec.template.spec.containers[0].volumeMounts[2].mountPath: /opt/chipster/web-root/assets/conf
  spec.template.spec.containers[0].volumeMounts[2].name: app-conf
  spec.template.spec.volumes[2].name: app-conf
  spec.template.spec.volumes[2].secret.secretName: web-server-app$subproject_postfix
" false

if [ -z $subproject ]; then
  web_server_host="$PROJECT.$DOMAIN"
else
  web_server_host="${subproject}-$PROJECT.$DOMAIN"
fi

patch_kind_and_name $template_dir/web-server.yaml Route web-server$subproject_postfix "
  spec.host: $web_server_host
  metadata.annotations.\"console.alpha.openshift.io/overview-app-route\": \"true\"
" false

# backup monitoring is too slow
patch_kind_and_name $template_dir/backup.yaml Route backup-admin$subproject_postfix "
  metadata.annotations.\"haproxy.router.openshift.io/timeout\": \"120s\"
" false

patch_kind_and_name $template_dir/file-broker.yaml Route file-broker-admin$subproject_postfix "
  metadata.annotations.\"haproxy.router.openshift.io/timeout\": \"120s\"
" false
