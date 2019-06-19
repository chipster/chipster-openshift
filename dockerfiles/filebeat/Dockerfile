FROM docker.elastic.co/beats/filebeat:7.1.1
COPY chipster-openshift/filebeat/filebeat.yml /usr/share/filebeat/filebeat.yml
USER root
RUN chown root:filebeat /usr/share/filebeat/filebeat.yml
USER filebeat
CMD filebeat
