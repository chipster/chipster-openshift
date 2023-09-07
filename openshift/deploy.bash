#!/bin/bash

set -e

private_conf_dir="$1"
default_conf_dir="$(dirname "$0")"
oc_project=$(oc project -q)

# compare configuration dir name and oc project to make sure correct configuration is applied
if [ -s "$private_conf_dir" ]; then
    conf_dir=$(basename $private_conf_dir)

    if [ $conf_dir != $oc_project.rahtiapp.fi ]; then
        echo "wrong project. oc: $oc_project, dir: $conf_dir"
        exit 1
    fi

    echo "Deploy $private_conf_dir to $oc_project"
else
    echo "Deploy default deployment to $oc_project"
fi

tmp_dir=$(mktemp -d -t deploy-chipster)
echo "Creating temp dir $tmp_dir"

echo "Copy kustomize files"
# copy default kustomize dir, because we want to produce its base version with Helm
cp -r $default_conf_dir/kustomize $tmp_dir

if [ -s "$private_conf_dir" ]; then
    # copy our overlay next to it, so that it doesn't need to know the path to tmp_dir
    # use $conf_dir (e.g. chipster-beta.rahtiapp.fi) as its name
    mkdir $tmp_dir/kustomize/overlays/$conf_dir
    cp -r $private_conf_dir/kustomize/* $tmp_dir/kustomize/overlays/$conf_dir
fi

#ls $tmp_dir/kustomize/*/*

echo "** Helm"
if [ -s "$private_conf_dir" ]; then
    oc get secret passwords -o json | jq '.data."values.json"' -r | base64 -d \
        | helm template helm-instance-name $default_conf_dir/helm/chipster -f - -f $private_conf_dir/helm/values.yaml > $tmp_dir/kustomize/base/helm-output.yaml
else
    oc get secret passwords -o json | jq '.data."values.json"' -r | base64 -d \
        | helm template helm-instance-name $default_conf_dir/helm/chipster -f - > $tmp_dir/kustomize/base/helm-output.yaml
fi

echo "** Kustomize"
if [ -s "$private_conf_dir" ]; then
    oc kustomize $tmp_dir/kustomize/overlays/$conf_dir > $tmp_dir/kustomized.yaml
else
    oc kustomize $tmp_dir/kustomize/base > $tmp_dir/kustomized.yaml
fi

echo "** Apply"

oc apply -f $tmp_dir/kustomized.yaml

rm -rf $tmp_dir