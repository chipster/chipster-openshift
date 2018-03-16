FROM shibboleth
	
COPY chipster-web-server /opt/

RUN  mkdir -p /opt/chipster-web-server/webroot \
    && chmod -R ugo+rwx /opt/chipster-web-server

WORKDIR /opt/chipster-web-server
	
# start all three processes	
CMD ["bash", "-c", "/etc/init.d/apache2 start; shibd start; exec java -XX:+UseSerialGC -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Xss228k -Xms32m -Xmx128m -cp lib/*: fi.csc.chipster.shibboleth.Shibboleth"]