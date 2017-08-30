FROM chipster-web-server

COPY tools /opt/chipster-web-server/tools

RUN mkdir -p /opt/chipster \
  && cd /opt/chipster \
  && ln -s /mnt/tools/current tools

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.toolbox.ToolboxService"]
