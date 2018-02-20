#!/bin/bash

if [ -z "$2" ]; then 
	echo "Usage: bash update_shibd_confs.bash CERT_DIR CONF_DIR"
	echo ""
	echo "Replaces the dockerfile in given the OpenShfit build with the file dockerfiles/BUILD_NAME/Dockerfile"
	echo ""
	echo "Generate certificate and private key"
	echo "  /usr/sbin/shib-keygen -h HOSTNAME -y 3 -e ENTITY_ID -o CERT_DIR"
	echo ""
	echo "Download metadata certifificate"
	echo "  wget https://wiki.eduuni.fi/download/attachments/27297785/haka_testi_2015_sha2.crt -O CERT_DIR/metadata.crt"
	echo ""
	exit 1 
fi

cert_dir="$1"
conf_dir="$2"

if [[ $(oc get secret shibboleth-shibd-conf) ]]; then
  oc delete secret shibboleth-shibd-conf  
fi

oc create secret generic shibboleth-shibd-conf \
  	--from-file=$conf_dir \
  	--from-file=$cert_dir
  	
oc rollout latest shibboleth