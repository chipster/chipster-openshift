#!/bin/bash

mkdir -p $CHIPSTER_CLONE_PATH
cd $CHIPSTER_CLONE_PATH

# clone main projects to the tmp dir for building
git clone --branch ${CHIPSTER_BRANCH:-openshift} --single-branch https://github.com/chipster/chipster.git --depth=1

#rm -rf chipster/.git