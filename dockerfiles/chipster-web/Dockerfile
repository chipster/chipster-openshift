FROM chipster-web-server

USER 0

RUN mkdir /opt/chipster-web && chmod ugo+rwx /opt/chipster-web

# no need to build these projects, clone directly to /opt
RUN cd /opt; git clone --branch ${CLIENT_BRANCH:-openshift} --single-branch https://github.com/chipster/chipster-web.git --depth=1 && chmod -R ugo+rwx /opt/chipster-web && rm -rf chipster-web/.git

RUN echo $"{\n\
  "proxies": ["http://session-db-${OPENSHIFT_BUILD_NAMESPACE}.dac-oso.csc.fi/"],\n\
  "auth": "http://auth-${OPENSHIFT_BUILD_NAMESPACE}.dac-oso.csc.fi/",\n\
  "fileBroker": "http://file-broker-${OPENSHIFT_BUILD_NAMESPACE}.dac-oso.csc.fi/",\n\
  "sessionDb": "http://session-db-${OPENSHIFT_BUILD_NAMESPACE}.dac-oso.csc.fi/",\n\
  "sessionDbEvents": "ws://session-db-events-${OPENSHIFT_BUILD_NAMESPACE}.dac-oso.csc.fi/",\n\
  "toolbox": "http://toolbox-${OPENSHIFT_BUILD_NAMESPACE}.dac-oso.csc.fi/"\n\
}\n"\
> /opt/chipster-web/js/json/config.json

USER 1001

WORKDIR /opt/chipster-web-server  

CMD java -cp lib/*: fi.csc.chipster.web.WebServer
