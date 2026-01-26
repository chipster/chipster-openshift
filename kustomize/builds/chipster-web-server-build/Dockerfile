# image for building java components

FROM chipster-web-server

# build the chipster project

# options for setting java version
# 1) parameter for ./gradlew -Dorg.gradle.java.home=/JDK_PATH
# 2) export JAVA_HOME=/JDK_PATH
# 3) update-java-alternatives -s java-1.11.0-openjdk-amd64 \

RUN cd /home/user/chipster-web-server \
	&& export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8 \
	&& ./gradlew -v \
	&& ./gradlew distTar \
	&& tar -zxf build/distributions/chipster-web-server.tar.gz \
	&& mkdir -p /opt/chipster/lib \
	&& mv chipster-web-server/lib/*.jar /opt/chipster/lib \
	&& chmod -R ugo+rwx /opt/chipster \
	&& ls -lah /opt/chipster/lib \
	&& rm -rf ../chipster-web-server

WORKDIR /opt/chipster

CMD ["echo", "ERROR: this is a build image and shouldn't be run, use chipster-web-server-java instead"]
