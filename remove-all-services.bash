#!/bin/bash

oc delete dc --all
oc delete routes --all
oc delete pods --all

for s in $(oc get secret -o name | grep -v passwords); do 
  oc delete $s
done

for s in $(oc get service -o name | grep -v glusterfs-dynamic-); do 
  oc delete $s
done