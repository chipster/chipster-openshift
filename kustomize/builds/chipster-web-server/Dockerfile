FROM base-java-utils

COPY . chipster-web-server

# build the new chipster project

# options for setting java version
# 1) parameter for ./gradlew -Dorg.gradle.java.home=/JDK_PATH
# 2) export JAVA_HOME=/JDK_PATH
# 3) update-java-alternatives -s java-1.11.0-openjdk-amd64 \

RUN cd chipster-web-server \
	&& export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8 \
	&& ./gradlew distTar \
	&& tar -zxf build/distributions/chipster-web-server.tar.gz \
	&& mkdir -p /opt/chipster/lib \
	&& mv chipster-web-server/lib/*.jar /opt/chipster/lib \
	&& chmod -R ugo+rwx /opt/chipster \
	&& ls -lah /opt/chipster/lib \
	&& rm -rf ../chipster-web-server

WORKDIR /opt/chipster

# disable TLSv1.3, because downloads from ha-proxy (a3s.fi) fail at key update after 128 GiB
CMD java -cp lib/*: -Djdk.tls.client.protocols="TLSv1.2" ${JAVA_CLASS:-fi.csc.chipster.rest.ServerLauncher}
