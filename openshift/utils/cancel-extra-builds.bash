#!/bin/bash

set -e

cancel_build () {

    bc=$1
    echo $bc;
    for build in $(oc get build -l build=$bc | grep -e Running -e New | sed '$d' | cut -d " " -f 1); do
    echo cancel $build
    oc cancel-build $build;
    done
}

if [ -z "$1" ]; then
    echo cancel extra builds from all build configs
    for bc in $(oc get bc -o name | cut -d "/" -f 2); do
        cancel_build $bc
    done
    
else
    cancel_build $1
fi