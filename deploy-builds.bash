#!/bin/bash

set -e

source scripts/utils.bash

if ! kubectl --help > /dev/null 2>&1; then
  echo "Error: command 'kubectl' not found"
  exit 1
fi

if ! kubectl kustomize --help > /dev/null 2>&1; then
  echo "Error: command 'kubectl kustomize' not found, please update your kubectl"
  exit 1
fi

export PROJECT=$(get_project)
export DOMAIN=$(get_domain)

branch="$1"

if [ -n "$branch" ]; then
  echo "Error: this script doesn't have a branch parameter anymore. Please set appropriate branches in private patches. "
  echo
  exit 1
fi

private_config_path=" ../chipster-private/confs"

# better to do this outside repo
build_dir=$(make_temp chipster-openshift_deploy-builds)
# build_dir="build_temp"
# rm -rf build_temp
# mkdir $build_dir

echo -e "build dir is \033[33;1m$build_dir\033[0m"

base_dir="$build_dir/builds"

mkdir -p $base_dir

echo "copy Kustomize yaml files"
cp kustomize/builds/*.yaml $base_dir

echo "create base BuildConfigs and ImageStreams"

# use oc templates to put Dockerfiles to BuildConfigs and to copy ImageStreams for each build
for build_template in kustomize/builds/*/*.yaml; do
  build=$(basename $build_template .yaml)
  template_dir=$(dirname $build_template)

  echo $build

  cat $build_template \
    | yq e - -o=json \
    | jq .spec.source.dockerfile="$(cat $template_dir/Dockerfile | jq -s -R .)" \
    > $base_dir/$build-bc.yaml

  oc process -f templates/imagestreams/imagestream.yaml --local -p NAME=$build \
  > $base_dir/$build-is.yaml

  # modify the object in memory in the write to the same file
  echo "$(cat $base_dir/kustomization.yaml | yq e - -o=json | jq '.resources += ["'$build-bc.yaml'"]' | yq e - )" > $base_dir/kustomization.yaml
  echo "$(cat $base_dir/kustomization.yaml | yq e - -o=json | jq '.resources += ["'$build-is.yaml'"]' | yq e - )" > $base_dir/kustomization.yaml  
done

# copy builds-mylly overlay to the build dir in case this deployment uses it
cp -r kustomize/builds-mylly $build_dir

private_all_kustomize_path="$private_config_path/chipster-all/builds"
private_kustomize_path="$private_config_path/$PROJECT.$DOMAIN/builds"

if [ -z $private_all_kustomize_path ]; then
  echo "chipster-all not found"
else
  echo "copy chipster-all"
  mkdir -p $build_dir/chipster-all
  cp -r $private_all_kustomize_path/* $build_dir/chipster-all
fi

if [ -f $private_kustomize_path/kustomization.yaml ]; then
  echo "create overlay from $private_kustomize_path"

  overlay_dir="$build_dir/overlay"
  mkdir -p $overlay_dir

  # copy the overlay to our build dir
  cp -r $private_kustomize_path/* $overlay_dir

  apply_dir="$overlay_dir"
else
  echo "using default kustomization"
  apply_dir="$base_dir"
fi

echo "apply to server $apply_dir"
apply_out="$build_dir/apply.out"
kubectl kustomize $apply_dir  | oc apply -f - | tee $apply_out | grep -v unchanged
echo $(cat $apply_out | grep unchanged | wc -l) objects unchanged

echo "delete build dir $build_dir"
rm -rf $build_dir
