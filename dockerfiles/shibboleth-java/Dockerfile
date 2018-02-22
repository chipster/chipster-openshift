FROM shibboleth

COPY . /opt/sso-test/

# build the project and get all .jar files from the .tgz (this project and dependencies)
RUN cd /opt/sso-test \
	&& ./gradlew distTar \
	&& tar -xf build/distributions/sso-test.tar \
	&& mv sso-test/lib .

WORKDIR /opt/sso-test
	
# start all three processes	
CMD ["bash", "-c", "/etc/init.d/apache2 start; shibd start; exec java -XX:+UseSerialGC -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Xss228k -Xms32m -Xmx128m -cp lib/*: fi.csc.shibboleth.example.ShibbolethService"]