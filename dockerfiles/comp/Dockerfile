FROM comp-base

COPY chipster-web-server /opt/

WORKDIR /opt/chipster-web-server

RUN mkdir -p /opt/chipster && cd /opt/chipster && ln -s /mnt/tools/current tools

# Legacy DirectoryLayout requires these folders to exist
USER 0
RUN cd /opt/chipster-web-server && mkdir security

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.comp.RestCompServer"]
