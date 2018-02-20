#!/bin/bash

if [ -z "$1" ]; then 
	echo "Usage: bash update_shibd_confs.bash APACHE_CONF_DIR"
	echo ""
	echo ""
	exit 1 
fi

conf_dir="$1"

if [[ $(oc get secret shibboleth-apache-conf) ]]; then
  	oc delete secret shibboleth-apache-conf  
fi
  	

oc create secret generic shibboleth-apache-conf \
  --from-file=$conf_dir

oc rollout latest shibboleth