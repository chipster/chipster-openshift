FROM chipster-web-server

COPY tools /opt/chipster-web-server/tools
COPY manual /opt/chipster-web/src/assets/manual

RUN mkdir -p /opt/chipster \
  && cd /opt/chipster \
  && ln -s /mnt/tools/current tools

CMD ["java", "-XX:+UseSerialGC", "-XX:+TieredCompilation", "-XX:TieredStopAtLevel=1", "-XX:MinHeapFreeRatio=20", "-XX:MaxHeapFreeRatio=40", "-XX:GCTimeRatio=4", "-XX:AdaptiveSizePolicyWeight=90", "-Xss228k", "-Xms32m", "-Xmx128m", "-cp", "lib/*:", "fi.csc.chipster.toolbox.ToolboxService"]
