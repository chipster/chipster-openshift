FROM chipster

COPY . /tmp/build/chipster-web-server/

# build the new chipster project
RUN cd /tmp/build/chipster-web-server \
	&& cp /opt/chipster/lib/chipster-*.jar . \
	&& gradle distTar \
	&& tar -zxf build/distributions/chipster-web-server.tar.gz \
	&& mkdir -p /opt/chipster-web-server/lib \
	&& mv *.jar /opt/chipster-web-server/lib \
	&& mv chipster-web-server/lib/*.jar /opt/chipster-web-server/lib \
 	&& chmod -R ugo+rwx /opt/chipster-web-server \
 	&& rm -rf /tmp/build/chipster-web-server

WORKDIR /opt/chipster-web-server

CMD java -cp lib/*: ${JAVA_CLASS:-fi.csc.chipster.rest.ServerLauncher}
