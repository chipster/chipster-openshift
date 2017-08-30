#!/bin/bash

set -x
set -e

source script-utils/deploy-utils.bash

function update_dockerfile {
	build_name=$1	
	oc get bc $build_name -o json | jq .spec.source.dockerfile="$(cat  dockerfiles/$build_name/Dockerfile | jq -s -R .)" | oc replace bc $build_name -f -	
}


# oc delete is base && oc delete bc base && \
oc new-build --name=base -D - < dockerfiles/base/Dockerfile && \
retry oc logs -f bc/base

# oc delete is chipster && oc delete bc chipster &&\
oc new-build https://github.com/chipster/chipster.git -D - < dockerfiles/chipster/Dockerfile &&\
retry oc logs -f bc/chipster


oc new-build https://github.com/chipster/chipster-web-server.git -D - < dockerfiles/chipster-web-server/Dockerfile

update_dockerfile chipster-web-server  
oc start-build chipster-web-server --follow
#oc start-build chipster-web-server --from- ../chipster-web-server --follow


# oc start-build chipster-web-server --from-file dockerfiles/chipster-web-server/Dockerfile --follow


# oc delete is chipster-web-server-js && oc delete bc chipster-web-server-js && \
oc new-build --name chipster-web-server-js https://github.com/chipster/chipster-web-server.git -D - < dockerfiles/chipster-web-server-js/Dockerfile && \
retry oc logs -f bc/chipster-web-server-js

# oc delete is toolbox && oc delete bc toolbox && \
oc new-build https://github.com/chipster/chipster-tools.git --name=toolbox -D - < dockerfiles/toolbox/Dockerfile && \
retry oc logs -f bc/toolbox

PROJECT=$(get_project)
DOMAIN=$(get_domain)

# oc delete is web-server && oc delete bc web-server && \
service_locator="http://service-locator-$PROJECT.$DOMAIN" &&\
oc new-build https://github.com/chipster/chipster-web.git --name=web-server -D - < dockerfiles/web-server/Dockerfile -e SERVICE_LOCATOR=$service_locator && \
retry oc logs -f bc/web-server

# oc delete is comp-base && oc delete bc comp-base && \
oc new-build --name=comp-base -D - < dockerfiles/comp-base/Dockerfile  && \
retry oc logs -f bc/comp-base

# oc delete is comp && oc delete bc comp && \
oc new-build --name=comp --source-image=chipster-web-server --source-image-path=/opt/chipster-web-server:chipster-web-server -D - < dockerfiles/comp/Dockerfile
update_dockerfile comp
oc start-build comp --follow

# oc delete is h2 && oc delete bc h2 && \
oc new-build --name=h2 . -D - < dockerfiles/h2/Dockerfile
oc start-build h2 --from-file dockerfiles/h2/Dockerfile
retry oc logs -f bc/h2
