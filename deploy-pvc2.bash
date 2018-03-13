#!/bin/bash

for f in pvc/*.yaml; do
   if ! oc get pvc $(basename $f .yaml) -o name > /dev/null 2>&1 ; then
     oc create -f $f
   fi
done
