#!/bin/bash

source script-utils/deploy-utils.bash

echo "Processing templates"
bash script-utils/process-templates.bash

for f in processed-templates/pvcs/*.yaml; do
   if ! oc get pvc $(basename $f .yaml) -o name > /dev/null 2>&1 ; then
     oc create -f $f
   fi
done

rm -rf processed-templates/
