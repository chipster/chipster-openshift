#!/bin/bash

source scripts/utils.bash
set -e

PROJECT=$(get_project)

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

keys+="monitoring-password"$'\n'

# better to do this outside repo
build_dir=$(make_temp chipster-openshift_generate-passwords)
echo -e "build dir is \033[33;1m$build_dir\033[0m"

secret_file="$build_dir/passwords.json"
get_secret passwords$subproject_postfix $subproject \
	| jq ".items[0].metadata.labels.subproject=\"chipster-$subproject-passowrds\"" > $secret_file
		
for key in $keys; do
  add_literal_to_secret $secret_file "$key" "$(generate_password)"
done

add_literal_to_secret $secret_file "jws-private-key-auth" "$(openssl ecparam -genkey -name secp521r1 -noout)"
add_literal_to_secret $secret_file "jws-private-key-session-db" "$(openssl ecparam -genkey -name secp521r1 -noout)"

echo "creata serviceaccount for scheduler"
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bash-job-scheduler
EOF

#TODO why to json doesn't work?
oc adm policy add-role-to-user edit system:serviceaccount:chipster-beta:bash-job-scheduler

# kubectl apply -f - <<EOF
# apiVersion: authorization.openshift.io/v1'
# kind: RoleBinding
# metadata:
#   name: edit
#   namespace: $PROJECT
# roleRef:
#   name: edit
# subjects:
# - kind: ServiceAccount
#   name: bash-job-scheduler
#   namespace: $PROJECT
# userNames:
# - system:serviceaccount:$PROJECT:bash-job-scheduler
# EOF

echo "apply changes"
oc apply -f $secret_file

echo "delete build dir $build_dir"
rm -rf $build_dir