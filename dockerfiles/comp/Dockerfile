FROM comp-base

COPY chipster-web-server /opt/

WORKDIR /opt/chipster-web-server

# Legacy DirectoryLayout requires this
RUN mkdir /opt/chipster-web-server/security

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.comp.RestCompServer"]
