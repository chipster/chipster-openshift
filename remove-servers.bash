#!/bin/bash

subproject="$1"

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
fi

oc delete all -l subproject=$subproject
oc delete secret -l subproject=$subproject

echo "Run this to delete volumes in $(oc project -q):"
echo "oc delete pvc -l subproject=$subproject"

 