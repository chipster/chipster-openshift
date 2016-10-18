#!/bin/bash

PROJECT=chipster-dev

oc new-project $PROJECT

oc new-build --dockerfile=dockerfiles/base --to base

oc delete is base && oc delete bc base && \
oc new-build --name=base -D - < dockerfiles/base/Dockerfile && \
oc logs -f bc/base

oc delete is chipster && oc delete bc chipster &&\
oc new-build https://github.com/chipster/chipster.git -D - < dockerfiles/chipster/Dockerfile &&\
oc logs -f bc/chipster

oc delete is chipster-web-server && oc delete bc chipster-web-server && \
oc new-build https://github.com/chipster/chipster-web-server.git -D - < dockerfiles/chipster-web-server/Dockerfile && \
oc logs -f bc/chipster-web-server

for component in auth file-broker scheduler service-locator session-db; do
	oc new-build --name=$component -D - < dockerfiles/$component/Dockerfile
done

oc delete is toolbox && oc delete bc toolbox && \
oc new-build https://github.com/chipster/chipster-tools.git --name=toolbox -D - < dockerfiles/toolbox/Dockerfile && \
oc logs -f bc/toolbox

oc delete is web-server && oc delete bc web-server && \
oc new-build https://github.com/chipster/chipster-web.git --name=web-server -D - < dockerfiles/web-server/Dockerfile -e SERVICE_LOCATOR=http://service-locator-chipster-dev.dac-oso.csc.fi && \
oc logs -f bc/web-server

oc delete is comp-base && oc delete bc comp-base && \
oc new-build --name=comp-base -D - < dockerfiles/comp-base/Dockerfile  && \
oc logs -f bc/comp-base

oc delete is comp && oc delete bc comp && \
oc new-build --name=comp --source-image=chipster-web-server --source-image-path=/opt/chipster-web-server:chipster-web-server -D - < dockerfiles/comp/Dockerfile  && \
oc logs -f bc/comp

oc deploy auth --latest
oc deploy service-locator --latest
oc deploy session-db --latest
oc deploy file-broker --latest
oc deploy scheduler --latest
oc deploy toolbox --latest
oc deploy comp --latest
oc deploy web --latest
