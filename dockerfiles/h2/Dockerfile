
# Pull base image.
FROM base

# Install H2
RUN \
  cd /tmp && \
  wget http://www.h2database.com/h2-2017-06-10.zip && \
  unzip h2-2017-06-10.zip && \
  rm -f h2-2017-06-10.zip && \
  mkdir -p /opt/h2 && \
  mv /tmp/h2 /opt && \
  mkdir -p /opt/h2-data

# Expose ports.
#   - 1521: H2 Server
#   -   81: H2 Console
EXPOSE 1521 8081

# Define default command
CMD java -XX:+UseSerialGC -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Xss228k -Xms32m -Xmx128m -cp /opt/h2/bin/h2*.jar org.h2.tools.Server -web -webAllowOthers -webPort 8081 -tcp -tcpAllowOthers -tcpPort 1521 -baseDir /opt/h2-data