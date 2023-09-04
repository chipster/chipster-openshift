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
oc kustomize $tmp_dir/kustomize/overlays/$conf_dir > $tmp_dir/kustomized.yaml
cat $tmp_dir/kustomized.yaml | yq ea -o=json > $tmp_dir/kustomized.json


# the Helm templates generate chipster configs to yaml object enabling kustomization
# convert the yaml object to string, because Java code expects to find them in one file
# now done with yq (v4) and jq, perhaps we could even write a simple python program for this

# separate secrets from other objects
cat $tmp_dir/kustomized.json | jq 'select(.kind != "Secret")' > $tmp_dir/other.json

# this would make it in one line, but produces ugly one-line json configs
# cat $tmp_dir/kustomized.json | jq 'select(.kind == "Secret") | .stringData."chipster.yaml" = (.chipsterConfig | tostring) | del(.chipsterConfig)' > $tmp_dir/kube-secrets.json

# let's handle secrets one by one to get pretty yaml output
cat $tmp_dir/kustomized.json | jq 'select(.kind == "Secret")' > $tmp_dir/chipster-secrets.json

# split the multi-document
mkdir $tmp_dir/secrets
pushd $tmp_dir/secrets
yq --output-format=json -s '.metadata.name' ../chipster-secrets.json
popd

# create emtpy file for results
echo "" > $tmp_dir/kube-secrets.json

# for each secret
for secret_file in $tmp_dir/secrets/*.json; do
    # echo $secret_file
    # convert chipster config to pretty yaml and json encode it
    encoded_conf="$(cat $secret_file | jq .chipsterConfig | yq -P | jq -Rsa .)"

    # remove .chipsterConfig from the secret and assign in pretty yaml
    cat $secret_file | jq 'del(.chipsterConfig) | .stringData."chipster.yaml" = '"$encoded_conf" >> $tmp_dir/kube-secrets.json
done

echo "** Apply"
oc apply -f $tmp_dir/kube-secrets.json
oc apply -f $tmp_dir/other.json

rm -rf $tmp_dir