#!/bin/bash

BRANCH=${1:-openshift}

cd $CHIPSTER_WEB_BUILDS
BUILD=$(get_next_build)_$BRANCH

mkdir -p $TMPDIR_PATH/build 
cd $TMPDIR_PATH/build

git clone --branch $BRANCH --single-branch https://github.com/chipster/chipster-web.git --depth=1

rm -rf chipster-web/.git

# generate a client configuration
echo '{
  "proxies": ["http://session-db-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/"],
  "auth": "http://auth-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/",
  "fileBroker": "http://file-broker-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/",
  "sessionDb": "http://session-db-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/",
  "sessionDbEvents": "ws://session-db-events-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/",
  "toolbox": "http://toolbox-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/"
}' > chipster-web/js/json/config.json

mv chipster-web $CHIPSTER_WEB_BUILDS/$BUILD

cd $CHIPSTER_WEB_BUILDS
create_links $BUILD $BRANCH