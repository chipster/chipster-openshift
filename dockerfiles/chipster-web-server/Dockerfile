FROM chipster

COPY . /tmp/build/chipster-web-server/

# build the new chipster project

# options for setting java version
# 1) parameter for ./gradlew -Dorg.gradle.java.home=/JDK_PATH
# 2) export JAVA_HOME=/JDK_PATH
# 3) update-java-alternatives -s java-1.11.0-openjdk-amd64 \

RUN cd /tmp/build/chipster-web-server \
	&& cp /opt/chipster/lib/chipster-*.jar . \
	&& ./gradlew distTar \
	&& tar -zxf build/distributions/chipster-web-server.tar.gz \
	&& mkdir -p /opt/chipster-web-server/lib \
	&& cp *.jar /opt/chipster-web-server/lib \
	&& mv *.jar /opt/chipster/lib \
	&& mv chipster-web-server/lib/*.jar /opt/chipster-web-server/lib \
	&& mv conf /opt/chipster-web-server/ \
	&& chmod -R ugo+rwx /opt/chipster-web-server \
	&& rm -rf /tmp/build/chipster-web-server

WORKDIR /opt/chipster-web-server

CMD java -cp lib/*: ${JAVA_CLASS:-fi.csc.chipster.rest.ServerLauncher}
