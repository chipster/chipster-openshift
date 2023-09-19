#!/bin/bash

set -e

private_conf_dir="$1"

if [ -s "$1" ]; then
    # first argument is the private_conf_dir. Remaining arguments are passed to Helm
    shift
fi

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

# Create a temp dir. Don't store the temporary Helm output in the repository folders to avoid
# committing it by accident. It contains a few passwords.
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

    export CHIPSTER_KUSTOMIZE_DIR="overlays/$conf_dir"

    # print helm output for debugging
    
    # oc get secret passwords -o json | jq '.data."values.json"' -r | base64 -d | helm template chipster $script_dir/helm/chipster  \
    #         -f - \
    #         -f $private_conf_dir/helm/values.yaml \
    #         --post-renderer $script_dir/utils/kustomize-post-renderer.bash \
    #         "$@"

    oc get secret passwords -o json | jq '.data."values.json"' -r | base64 -d | helm upgrade chipster $script_dir/helm/chipster  \
            --install \
            -f - \
            -f $private_conf_dir/helm/values.yaml \
            --post-renderer $script_dir/utils/kustomize-post-renderer.bash \
            "$@"
        
else

    export CHIPSTER_KUSTOMIZE_DIR="base"

    oc get secret passwords -o json | jq '.data."values.json"' -r | base64 -d | helm upgrade chipster $script_dir/helm/chipster  \
            --install \
            -f - \
            --post-renderer $script_dir/utils/kustomize-post-renderer.bash
fi

rm -rf $tmp_dir