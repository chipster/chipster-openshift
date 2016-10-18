FROM base

# copy the git workspace from the host to container
COPY . /tmp/build/chipster/

RUN cd /tmp/build/chipster \
	&& export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8 \
	&& ant package-jar \
	&& mkdir -p /opt/chipster/lib \
	&& mv dist/chipster-*.jar /opt/chipster/lib \
	&& rm -rf /tmp/build/chipster \
	&& chmod -R ugo+rwx /opt/chipster
