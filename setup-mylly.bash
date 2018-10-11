#!/bin/bash

set -e

function secret_to_dir {
  secret="$1"
  dir="$2"
  
  mkdir -p $dir

  keys="$(oc get secret $secret -o json | jq .data | jq keys[] -r)"
  while read -r key; do
    echo "copying $key to $dir/$key"
	oc get secret $secret -o json | jq .data.\"$key\" -r | base64 -D > $dir/$key
  done <<< "$keys"
}

function dir_to_secret {
  secret="$1"
  dir="$2"

  cmd="oc delete secret $secret;"
  cmd="$cmd oc create secret generic $secret "  

  for file_path in $dir/*; do
    file="$(basename $file_path)"
    cmd="$cmd --from-file=$file=$file_path"
  done

  echo "$cmd"
  eval "$cmd"	  
}



mkdir -p mylly-conf

# configure the app to use Kielipankki tools and manuals
secret_to_dir web-server-app-conf mylly-conf/web-server-app-conf 
    yq n modules [] \
  | yq w - modules[0] Kielipankki \
  | yq w - manual-path assets/manual/kielipankki/manual/ \
  | yq w - manual-tool-postfix .en.src.html \
  | yq w - app-name Mylly \
  | yq w - custom-css assets/manual/kielipankki/manual/app-mylly-styles.css \
  | yq w - favicon assets/manual/kielipankki/manual/app-mylly-favicon.png \
  | yq w - home-path assets/manual/kielipankki/manual/app-home.html \
  | yq w - home-header-path assets/manual/kielipankki/manual/app-home-header.html \
  | yq w - contact-path assets/manual/kielipankki/manual/app-contact.html \
   > mylly-conf/web-server-app-conf/mylly.yaml
dir_to_secret web-server-app-conf mylly-conf/web-server-app-conf

oc new-build --name toolbox-mylly https://github.com/CSCfi/Kielipankki-mylly.git#dev-tools -D - < dockerfiles/toolbox/Dockerfile && sleep 1 && oc logs -f bc/toolbox-mylly

oc delete bc toolbox
oc delete is toolbox

# We need both tools and manual from the toolbox-mylly image, but the oc command takes only one source-image-path.
# Use it to get the tools and configure the image change trigger.
oc new-build --name toolbox https://github.com/chipster/chipster-tools.git -D - \
  --source-image=toolbox-mylly --source-image-path=/opt/chipster-web-server/tools/kielipankki/:tools/ \
  < dockerfiles/toolbox/Dockerfile
  
# Modify the build config to copy also the manual
#TODO The files end up to /opt/chipster-web/src/assets/manual/kielipankki/manual. What creates the last manual folder?
oc get bc toolbox -o json | jq '.spec.source.images[0].paths[1]={"destinationDir": "manual/kielipankki/", "sourcePath": "/opt/chipster-web/src/assets/manual/"}' | oc replace bc toolbox -f -
oc start-build toolbox --follow

bash rollout-services.bash