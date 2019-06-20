FROM shibboleth

COPY chipster-web-server /opt/

# openjdk packages should be in this order to make 11 default
RUN apt-get remove -y openjdk-8-jdk \
    && apt-get update -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:openjdk-r/ppa \
    && apt-get update -y \ 
    && apt-get upgrade -y \
    && apt-get install -y openjdk-11-jdk-headless \
    && apt-get clean

RUN  mkdir -p /opt/chipster-web-server/webroot \
    && chmod -R ugo+rwx /opt/chipster-web-server

WORKDIR /opt/chipster-web-server

# start all three processes	
CMD ["bash", "-c", "/etc/init.d/apache2 start; shibd start; exec java -XX:+UseSerialGC -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Xss228k -Xms32m -Xmx128m -cp lib/*: fi.csc.chipster.shibboleth.Shibboleth"]