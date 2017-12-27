FROM chipster

COPY . /tmp/build/chipster-web-server/

# build the new chipster project
RUN cd /tmp/build/chipster-web-server \
	&& cp /opt/chipster/lib/chipster-*.jar . \
	&& gradle distTar \
	&& tar -zxf build/distributions/chipster-web-server.tar.gz \
	&& mkdir -p /opt/chipster-web-server/lib \
	&& cp *.jar /opt/chipster-web-server/lib \
	&& mv *.jar /opt/chipster/lib \
	&& mv chipster-web-server/lib/*.jar /opt/chipster-web-server/lib \
	&& mv conf /opt/chipster-web-server/ \
 	&& chmod -R ugo+rwx /opt/chipster-web-server \
 	&& rm -rf /tmp/build/chipster-web-server

WORKDIR /opt/chipster-web-server

# smaller memory overhead 
# https://developers.redhat.com/blog/2017/04/04/openjdk-and-containers/
# https://developers.redhat.com/blog/2014/07/22/dude-wheres-my-paas-memory-tuning-javas-footprint-in-openshift-part-2/
CMD java -XX:+UseSerialGC -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Xss228k -Xms32m -Xmx128m -cp lib/*: ${JAVA_CLASS:-fi.csc.chipster.rest.ServerLauncher}
