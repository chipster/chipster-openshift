#!/bin/bash

mkdir -p $CHIPSTER_WEB_SERVER_PATH
mkdir -p $TMPDIR_PATH/build 

cd $TMPDIR_PATH/build

git clone --branch ${SERVER_BRANCH:-openshift} --single-branch https://github.com/chipster/chipster-web-server.git --depth=1

# build the new chipster project
cd chipster-web-server
cp $CHIPSTER_PATH/chipster-*.jar .
gradle distTar
tar -xf build/distributions/chipster-web-server.tar
cp chipster-web-server/lib/*.jar $CHIPSTER_WEB_SERVER_PATH
cd ..
rm -rf chipster-web-server
