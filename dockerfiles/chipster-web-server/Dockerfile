FROM chipster-jms

USER 0

WORKDIR /tmp/src

RUN mkdir /tmp/test

RUN mkdir -p /opt/chipster-web-server/lib # && chmod -R ugo+rwx /opt/chipster-web-server

RUN git clone --branch ${SERVER_BRANCH:-openshift} --single-branch https://github.com/chipster/chipster-web-server.git --depth=1

# build the new chipster project
RUN cp /opt/chipster/lib/chipster-*.jar /tmp/src/chipster-web-server && cd chipster-web-server && gradle distTar && tar -xf build/distributions/chipster-web-server.tar && cp chipster-web-server/lib/*.jar /opt/chipster-web-server/lib && rm -rf /tmp/src/chipster-web-server

USER 1001
EXPOSE 8080

WORKDIR /opt/chipster-web-server  
CMD java -cp lib/*: ${JAVA_CLASS:-fi.csc.chipster.rest.ServerLauncher}

