#!/bin/bash

set -e

private_conf_dir="$1"

shift

oc_project=$(oc project -q)
script_dir="$(dirname $(readlink -f "$0"))"

# echo private_conf_dir: $private_conf_dir
# echo oc_project: $oc_project
# echo script_dir: $script_dir

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
cp -r $script_dir/kustomize $tmp_dir

if [ -s "$private_conf_dir" ]; then
    # copy our overlay next to it, so that it doesn't need to know the path to tmp_dir
    # use $conf_dir (e.g. chipster-beta.rahtiapp.fi) as its name
    mkdir $tmp_dir/kustomize/overlays/$conf_dir
    cp -r $private_conf_dir/kustomize/* $tmp_dir/kustomize/overlays/$conf_dir
fi

pushd "$tmp_dir"/kustomize

echo "** Helm"
if [ -s "$private_conf_dir" ]; then

    export CHIPSTER_KUSTOMIZE_DIR="overlays/low-pod-quota"

    oc get secret passwords -o json | jq '.data."values.json"' -r | base64 -d | helm upgrade chipster $script_dir/helm/chipster  \
            --install \
            -f - \
            -f $private_conf_dir/helm/values.yaml \
            --post-renderer $script_dir/utils/kustomize-post-renderer.bash \
            "$@"

    # oc get secret passwords -o json | jq '.data."values.json"' -r | base64 -d \
    #     | helm upgrade chipster $script_dir/helm/chipster  \
    #         --install \
    #         -f - \
    #         -f $private_conf_dir/helm/values.yaml
            
    #         #  \
    #         # --post-renderer $script_dir/utils/kustomize-post-renderer.bash
        
else

    export CHIPSTER_KUSTOMIZE_DIR="base"

    oc get secret passwords -o json | jq '.data."values.json"' -r | base64 -d | helm upgrade chipster $script_dir/helm/chipster  \
            --install \
            -f - \
            --post-renderer $script_dir/utils/kustomize-post-renderer.bash
fi


# echo "** Apply"

# oc apply -f $tmp_dir/kustomized.yaml

rm -rf $tmp_dir