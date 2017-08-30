FROM comp-base

COPY chipster-web-server /opt/

RUN mkdir -p /opt/chipster/comp \
  && mv /opt/chipster-web-server/lib /opt/chipster \
  && cd /opt/chipster \
  && ln -s /mnt/tools/current tools \
  && mkdir -p /opt/chipster/comp/security

# Legacy DirectoryLayout assumes it's running here
WORKDIR /opt/chipster/comp

USER 0

CMD ["java", "-cp", "../lib/*:", "fi.csc.chipster.comp.RestCompServer"]
