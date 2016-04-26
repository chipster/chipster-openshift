#!/bin/bash

BRANCH=${1:-openshift}

cd $CHIPSTER_CLONE_BUILDS
BUILD=$(get_next_build)_$BRANCH

mkdir -p $TMPDIR_PATH/build 
cd $TMPDIR_PATH/build

git clone --branch $BRANCH --single-branch https://github.com/chipster/chipster.git --depth=1

rm -rf chipster/.git

mv chipster $CHIPSTER_CLONE_BUILDS/$BUILD

cd $CHIPSTER_CLONE_BUILDS
create_links $BUILD $BRANCH