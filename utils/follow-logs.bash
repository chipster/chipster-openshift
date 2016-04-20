#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Usgae: follow-logs.bash NAME"
    exit 0
fi

NAME="$1"

POD=$(oc get pods | grep $NAME | grep -v Terminating | grep -v Error | cut -d " " -f 1)

POD_COUNT="$(echo $POD | wc -l)"
if [ $POD_COUNT != 1 ]; then
  echo "Expecting 1 pod but found $POD_COUNT"
  oc get pods | grep $NAME
  exit 1
fi

#until oc logs $POD; do
# shorter output
until oc logs $POD 2>&1 | cut -d ":" -f 3 ; test ${PIPESTATUS[0]} -eq 0; do
  sleep 2
done

oc logs $POD --follow

sleep 1

until EXIT_CODE=$(oc get pod $POD -o json | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["status"]["containerStatuses"][0]["state"]["terminated"]["exitCode"];'); do
  sleep 1
done

exit $EXIT_CODE
