FROM chipster-jms

WORKDIR /tmp/src

RUN mkdir -p /opt/chipster-web-server/lib chmod -R ugo+rwx /opt/chipster-web-server

RUN git clone --branch ${API_BRANCH:-openshift} https://github.com/chipster/chipster-web-server.git --depth=1

# build the new chipster project
RUN cd chipster-web-server; gradle distTar ; tar -xf chipster-web-server/build/distributions/chipster-web-server.tar ; cp chipster-web-server/lib/*.jar /opt/chipster-web-server/lib ; rm -rf /tmp/src/chipster-web-server

USER 1001

EXPOSE 8080

WORKDIR /opt/chipster-web-server  
CMD java -cp lib/*: ${JAVA_CLASS:-fi.csc.chipster.rest.ServerLauncher}
