#!/bin/bash


mkdir -p $TOOLS_PATH
cd $TOOLS_PATH

git clone --branch ${TOOLS_BRANCH:-openshift} --single-branch https://github.com/chipster/chipster-tools.git --depth=1 

rm -rf chipster-tools/.git
