#!/bin/bash

set -e

source scripts/utils.bash

bash ../shibboleth-openshift/deploy-shibboleth.bash \
  --name haka \
  --support chipster@csc.fi \
  --logo https://raw.githubusercontent.com/chipster/chipster-web/master/src/assets/web-header-image.png \
  --hostname $PROJECT.$DOMAIN \
  --cert_dir "~/shibboleth_keys/$PROJECT.$DOMAIN-haka"
  
oc delete bc shibboleth-java; oc delete is shibboleth-java
oc new-build --name shibboleth-java --source-image=chipster-web-server --source-image-path=/opt/chipster-web-server:chipster-web-server -D - < dockerfiles/shibboleth-java/Dockerfile  && sleep 1 && oc logs -f bc/shibboleth-java

oc set volume dc/haka --add -t emptyDir --mount-path /opt/chipster-web-server/logs  	
oc set volume dc/haka --add -t secret --secret-name haka-conf --mount-path /opt/chipster-web-server/conf/

oc expose dc auth --port=80 --target-port=8013 --name auth-m2m
