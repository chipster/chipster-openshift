#!/bin/bash

set -e

if [ $# -eq 0 ]
then
  echo "Usgae: run-job.bash BASH_SCRIPT [IMAGE [ENVS_FILE]]"
  exit 0
fi

if [ -z "$2" ]
then
  IMAGE="base"
else
  IMAGE="$2"
fi



if [ -z "$3" ]
then
  ENVS_FILE=/dev/null
else
  ENVS_FILE=$3
fi

BASH_SCRIPT="$1"

# generate valid job names from the script name by 
# - removing the path and file extension
# - changing uppercase letters to lowercase
# - replacing any special characters with dashes 
JOB_NAME=build-$(basename $BASH_SCRIPT .bash | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z|0-9]/-/g' )

#echo "** Cancel the old deployment"
#if oc get dc $JOB_NAME -o name ; then
#  oc deploy $JOB_NAME --cancel
#fi

#echo "** Delete old deployment configs"
#if oc get dc $JOB_NAME -o name ; then
##if oc get dc $JOB_NAME -o name > /dev/null 2>&1 ; then
#  oc delete dc $JOB_NAME
#fi

#echo "** Delete old pods"
#if oc get pod -l deploymentconfig=$JOB_NAME -o name ; then
#  oc delete pod -l deploymentconfig=$JOB_NAME
#fi

#echo "** Delete old pods"
if oc get pod $JOB_NAME -o name ; then
  oc delete pod $JOB_NAME
fi

until ! oc get pod $JOB_NAME -o name ; do
  echo "Waiting for pod to disappear"
  sleep 1
done

#echo "** Delete the old job"
#if oc get job $JOB_NAME ; then
#  oc delete job $JOB_NAME
#fi

echo "** Start pod"
oc run $JOB_NAME --image 172.30.1.144:5000/chipster/$IMAGE -o name --restart='Never'

oc patch pod $JOB_NAME -p '{"spec":{"terminationGracePeriodSeconds":0}}'
#sleep 0.5
#oc deploy $JOB_NAME --cancel

echo "** Add volumes"
#oc set volume dc/$JOB_NAME --add -t pvc --mount-path /mnt/artefacts --claim-name artefacts
#oc set volume dc/$JOB_NAME --add -t emptyDir --mount-path /opt

#oc deploy $JOB_NAME --latest

function get_pod {
  echo $(oc get pod -l run=$JOB_NAME -o name | sed 's/pod\///')
}

until oc get pod -l run=$JOB_NAME | grep -v "Terminating" | grep -v NAME | grep Running ; do
  echo "Waiting for pod"
  sleep 2
done

POD=$(get_pod)

#until oc logs $(get_pod) ; do
#  echo "Waiting for logs"
#  sleep 2
#done


#echo "** Copy scripts"
#oc rsync $(dirname $BASH_SCRIPT)/ $POD:/tmp/job

#echo "** Run"
#oc rsh $POD bash /tmp/job/$(basename $BASH_SCRIPT)


