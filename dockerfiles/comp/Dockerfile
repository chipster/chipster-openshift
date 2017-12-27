FROM comp-base

COPY chipster-web-server /opt/

RUN mkdir -p /opt/chipster/comp \
  && chmod -R ugo+rwx /opt/chipster-web-server \
  && mv /opt/chipster-web-server/lib /opt/chipster \
  && cd /opt/chipster \
  && ln -s /mnt/tools/current tools \
  && mkdir -p /opt/chipster/comp/security

# Legacy DirectoryLayout assumes it's running here
WORKDIR /opt/chipster/comp

USER 0

CMD ["java", "-XX:+UseSerialGC", "-XX:+TieredCompilation", "-XX:TieredStopAtLevel=1", "-XX:MinHeapFreeRatio=20", "-XX:MaxHeapFreeRatio=40", "-XX:GCTimeRatio=4", "-XX:AdaptiveSizePolicyWeight=90", "-Xss228k", "-Xms32m", "-Xmx1g","-cp", "../lib/*:", "fi.csc.chipster.comp.RestCompServer"]
