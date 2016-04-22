#!/bin/bash

mkdir -p $CHIPSTER_PATH
mkdir -p $TMPDIR_PATH/build 

cd $TMPDIR_PATH/build

# copy to the tmp dir for building
cp -a $CHIPSTER_CLONE_PATH/* .

ls -lah

# build the old chipster project
export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8
cd chipster
ant package-jar
cp dist/chipster-*.jar $CHIPSTER_PATH
rm -rf /tmp/src/chipster
