#!/bin/bash

set -e

source scripts/utils.bash

export PROJECT=$(get_project)
export DOMAIN=$(get_domain)

branch="$1"

if [ -z "$branch" ]; then
  echo Error: branch not set.
  echo ""
  echo Usage: build-all.bash BRANCH
  echo 
  exit 1
fi

private_config_path=" ../chipster-private/confs"
hide_message="oc apply should be used on resource created by either oc create --save-config or oc apply"
build_dir="build_DO_NOT_COMMIT"
parts_dir="$build_dir/parts"

mkdir -p $parts_dir

echo "create build configs"

for build_template in templates/builds/*/*.yaml; do
  build=$(basename $build_template .yaml)
  echo $build
  oc process -f templates/builds/$build/$build.yaml --local -o json \
    -p NAME=$build-bc-template \
    -p BRANCH=$branch \
    -p GITHUB_SECRET="$(get_deploy_config $private_config_path bc-github-secret $PROJECT $DOMAIN)" \
    -p GENERIC_SECRET="$(get_deploy_config $private_config_path bc-generic-secret $PROJECT $DOMAIN)" \
    | jq .items[0].spec.source.dockerfile="$(cat templates/builds/$build/Dockerfile | jq -s -R .)" \
    > $parts_dir/$build-bc.yaml
    #| oc apply -f - | grep -v "$hide_message"

  oc process -f templates/imagestreams/imagestream.yaml --local -p NAME=$build \
  > $parts_dir/$build-is.yaml
  #| oc apply -f -  | grep -v "$hide_message"
done

echo "create imagestreams"
for is_yaml in $(ls templates/imagestreams/*.yaml | grep -v imagestream.yaml); do
  is=$(basename $is_yaml .yaml)
  echo $is
  oc process -f templates/imagestreams/$is.yaml --local -o json \
    > $parts_dir/$is-is.yaml 

done

echo "apply build configs"

do_merge=1

if [[ $do_merge == 0 ]]; then
  for t in $parts_dir/*.yaml; do
    echo $t
    oc apply -f $t
  done
else
  template="$build_dir/chipster_template.yaml"

  yq merge --append $parts_dir/*.yaml > $template

  apply_out="$build_dir/apply.out"
  oc apply -f $template | tee $apply_out | grep -v unchanged
  echo $(cat $apply_out | grep unchanged | wc -l) objects unchanged

  rm -rf $build_dir
fi
