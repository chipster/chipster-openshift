#!/bin/bash

source scripts/utils.bash
set -e

subproject="$1"

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
fi

echo "Generate passwords"
echo
  
authenticated_services=$(cat ../chipster-web-server/src/main/resources/chipster-defaults.yaml | grep ^service-password- | cut -d : -f 1 | sed s/service-password-//)

keys=""

for service in $authenticated_services; do
  keys+="service-password-$service"$'\n'
done

keys+="auth-db-password"$'\n'
keys+="session-db-db-password"$'\n'
keys+="job-history-db-password"$'\n'

build_dir="build_DO_NOT_COMMIT"
rm -rf $build_dir
mkdir -p $build_dir

secret_file="$build_dir/passwords.json"
get_secret passwords$subproject_postfix $subproject \
	| jq ".items[0].metadata.labels.subproject=\"chipster-$subproject-passowrds\"" > $secret_file
		
for key in $keys; do
  add_literal_to_secret $secret_file "$key" "$(generate_password)"
done

oc apply -f $secret_file

rm -rf $build_dir