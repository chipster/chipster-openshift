FROM web-server-code

COPY manual /opt/chipster-tools/manual

RUN rm /opt/chipster-web/assets/manual
RUN ln -s /opt/chipster-tools/manual /opt/chipster-web/assets/manual

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
