#!/bin/bash

CHIPSTER_CLONE_BUILD=${1:-latest_openshift}
BRANCH=$(echo $CHIPSTER_CLONE_BUILD | cut -d "_" -f 2)

cd $CHIPSTER_BUILDS
BUILD=$(get_next_build)_$BRANCH

mkdir -p $TMPDIR_PATH/build 
cd $TMPDIR_PATH/build

# copy to the tmp dir for building
cp -a $CHIPSTER_CLONE_BUILDS/$CHIPSTER_CLONE_BUILD/* .

# build the old chipster project
export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8
ant package-jar
mkdir -p $CHIPSTER_BUILDS/$BUILD/
mv dist/chipster-*.jar $CHIPSTER_BUILDS/$BUILD/

cd $CHIPSTER_BUILDS
create_links $BUILD $BRANCH
