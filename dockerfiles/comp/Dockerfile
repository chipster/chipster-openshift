FROM comp-base

COPY chipster-web-server /opt/

WORKDIR /opt/chipster-web-server

# Legacy DirectoryLayout requires these folders to exist
USER 0
RUN cd /opt/chipster-web-server && mkdir security

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.comp.RestCompServer"]
