FROM comp-base

COPY chipster-web-server /opt/

WORKDIR /opt/chipster-web-server

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.comp.RestCompServer"]
