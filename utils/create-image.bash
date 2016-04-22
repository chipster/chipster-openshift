#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Usgae: create-image.bash DOCKERFILE_DIR NAME [BASE_IMAGE]"
    exit 0
fi

if [ -z "$3" ]
then
  BASE_IMAGE="base"
else
  BASE_IMAGE=$3
fi

set -ex

DOCKERFILE_DIR="$1"
NAME="$2"

if oc get is $NAME > /dev/null 2>&1 ; then
  oc delete is/$NAME
fi

if oc get bc $NAME > /dev/null 2>&1 ; then
  oc delete bc/$NAME
fi

if oc get dc $NAME > /dev/null 2>&1 ; then
  oc delete dc/$NAME
fi

oc new-app --name $NAME $BASE_IMAGE~https://github.com/chipster/chipster-openshift.git \
--context-dir $DOCKERFILE_DIR --allow-missing-imagestream-tags --strategy=docker \
&& oc delete dc/$NAME

bash $(dirname "${BASH_SOURCE[0]}")/follow-logs.bash $NAME