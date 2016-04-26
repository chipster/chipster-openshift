#!/bin/bash

BRANCH=${1:-openshift}
CHIPSTER_BUILD=${2:-latest_openshift}

cd $CHIPSTER_WEB_SERVER_BUILDS
BUILD=$(get_next_build)_$BRANCH

mkdir -p $TMPDIR_PATH/build 
cd $TMPDIR_PATH/build

git clone --branch $BRANCH --single-branch https://github.com/chipster/chipster-web-server.git --depth=1

# build the new chipster project
cd chipster-web-server
cp $CHIPSTER_BUILDS/$CHIPSTER_BUILD/chipster-*.jar .
gradle distTar
tar -xf build/distributions/chipster-web-server.tar
mkdir -p $CHIPSTER_WEB_SERVER_BUILDS/$BUILD
cp chipster-web-server/lib/*.jar $CHIPSTER_WEB_SERVER_BUILDS/$BUILD

cd $CHIPSTER_WEB_SERVER_BUILDS
create_links $BUILD $BRANCH