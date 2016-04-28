#!/bin/bash

mkdir -p $TOOLS_BIN_PATH
cd $TOOLS_BIN_PATH

TOOLS_BIN_URL="http://bio.nic.funet.fi/pub/sci/molbio/chipster/dist/virtual_machines/3.7.2/tools/tools.tar.gz"

df -h
curl $TOOLS_BIN_URL -o tools.tar.gz
cat tools.tar.gz | pv -f | tar -zx

rm tools.tar.gz

ln -s $CHIPSTER_TOOLS_BIN_BUILD $CHIPSTER_TOOLS_BIN_PATH/../latest