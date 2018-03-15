#!/bin/bash

oc delete dc --all
oc delete routes --all
oc delete pods --all
oc delete secret --all

for s in $(oc get service -o name | grep -v glusterfs-dynamic-); do 
  oc delete $s
done