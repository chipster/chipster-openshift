FROM chipster-web-server-build

COPY tools /opt/chipster/toolbox/

RUN mkdir -p /opt/chipster \
  && cd /opt/chipster \
  && ln -s /mnt/tools tools \
  && chown -R 1000 /opt/chipster/toolbox \
  && chmod -R ugo+rwx /opt/chipster/toolbox

WORKDIR /opt/chipster/toolbox

CMD ["java", "-cp", "../lib/*:", "fi.csc.chipster.toolbox.ToolboxService"]
