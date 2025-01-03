FROM docker.elastic.co/beats/filebeat:7.16.2
COPY filebeat/filebeat.yml /usr/share/filebeat/filebeat.yml
USER root
RUN chown -R root:root /usr/share/filebeat
RUN chmod go-w /usr/share/filebeat/filebeat.yml
USER filebeat
CMD filebeat