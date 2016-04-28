#!/bin/bash

BRANCH=${1:-openshift}

cd $CHIPSTER_TOOLS_BUILDS
BUILD=$(get_next_build)_$BRANCH

mkdir -p $TMPDIR_PATH/build 
cd $TMPDIR_PATH/build

git clone --branch $BRANCH --single-branch https://github.com/chipster/chipster-tools.git --depth=1 

rm -rf chipster-tools/.git

mv chipster-tools $CHIPSTER_TOOLS_BUILDS/$BUILD

cd $CHIPSTER_TOOLS_BUILDS
create_links $BUILD $BRANCH
