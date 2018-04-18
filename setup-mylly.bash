#!/bin/bash

set -e

function secret_to_dir {
  secret="$1"
  dir="$2"
  
  mkdir -p $dir

  keys="$(oc get secret comp-conf -o json | jq .data | jq keys[] -r)"
  while read -r key; do
    echo "copying $key to $dir/$key"
	oc get secret comp-conf -o json | jq .data.\"$key\" -r | base64 -D > $dir/$key
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
oc get secret web-server-app-conf -o json | jq .data[\"chipster.yaml\"] -r | base64 -D \
  | yq w - modules [] \
  | yq w - modules[0] Kielipankki \
  | yq w - manual-postfix .en.src.html \
  | yq w - manual-relative-link-prefix https://www.kielipankki.fi/support/mylly/tool-placeholder/ \
   > mylly-conf/web-server-app-conf.yaml
oc delete secret web-server-app-conf
oc create secret generic web-server-app-conf --from-file=chipster.yaml=mylly-conf/web-server-app-conf.yaml

# there are multiple files in this secret
secret_to_dir comp-conf mylly-conf/comp
cat mylly-conf/comp/chipster.yaml | yq w - comp-module-filter-mode include > mylly-conf/comp/chipster.yaml_new
rm mylly-conf/comp/chipster.yaml
mv mylly-conf/comp/chipster.yaml_new mylly-conf/comp/chipster.yaml
dir_to_secret comp-conf mylly-conf/comp

rm -rf mylly-conf

oc delete bc toolbox
oc delete is toolbox
oc new-build --name toolbox https://github.com/CSCfi/Kielipankki-mylly.git -D - < dockerfiles/toolbox/Dockerfile
sleep 1
oc logs -f bc/toolbox


bash rollout-services.bash