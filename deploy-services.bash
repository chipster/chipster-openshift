#!/bin/bash

set -e

source script-utils/deploy-utils.bash

if [[ $(oc get dc) ]] || [[ $(oc get service -o name | grep -v glusterfs-dynamic-) ]] || [[ $(oc get routes) ]] ; then
  echo "The project is not empty"
  echo ""
  echo "The scirpt will continue, but it won't delete any extra deployments you possibly have."
  echo "Run the following command to remove all deployments:"
  echo ""
  echo "    bash delete-all-services.bash"
  echo ""
  echo "and if your want to remove volumes too:"
  echo ""
  echo "    oc delete pvc --all"
  echo ""
fi

echo "Processing templates"
bash script-utils/process-templates.bash

# it's faster to get lists just once
old_dcs="$(oc get dc -o name)"
old_services="$(oc get service -o name)"
old_routes="$(oc get route -o name)"

for f in processed-templates/deploymentconfigs/*.yaml; do
  # match only to the end of the line to separate "auth" and "auth-api"
  # quotes in the echo keep the new lines and the (second) dollar in the grep matches it
  if echo "$old_dcs" | grep -q "$(basename $f .yaml)$" ; then
    oc replace -f $f &
  else
    oc create -f $f &
  fi
done

wait

for f in processed-templates/deploymentconfigs/patches/*.yaml; do
  name=$(basename $f .yaml)
  oc patch dc $name -p "$(cat $f)" &
done

wait

# replace doesn't work for services, so delete all
for f in processed-templates/services/*.yaml; do
  name=$(basename $f .yaml)
  if echo "$old_services" | grep -q "$name$" ; then
    oc delete service "$name" &
  fi
done

wait

for f in processed-templates/services/*.yaml; do
  oc create -f $f &
done

wait

for f in processed-templates/routes/*.yaml; do
  if echo "$old_routes" | grep -q "$(basename $f .yaml)$" ; then
    oc replace -f $f &
  else
     oc create -f $f &
   fi
done

wait

rm -rf processed-templates/
