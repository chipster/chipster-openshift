#!/bin/bash

mkdir -p $CHIPSTER_WEB_PATH
cd $CHIPSTER_WEB_PATH

git clone --branch ${CLIENT_BRANCH:-openshift} --single-branch https://github.com/chipster/chipster-web.git --depth=1

rm -rf chipster-web/.git

# generate a client configuration
echo '{\n\
  "proxies": ["http://session-db-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/"],\n\
  "auth": "http://auth-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/",\n\
  "fileBroker": "http://file-broker-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/",\n\
  "sessionDb": "http://session-db-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/",\n\
  "sessionDbEvents": "ws://session-db-events-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/",\n\
  "toolbox": "http://toolbox-'${OPENSHIFT_BUILD_NAMESPACE}'.dac-oso.csc.fi/"\n\
}\n'\
> chipster-web/js/json/config.json


ln -s $CHIPSTER_WEB_BUILD $CHIPSTER_WEB_PATH/../latest