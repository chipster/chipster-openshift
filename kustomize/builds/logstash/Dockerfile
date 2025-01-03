FROM docker.elastic.co/logstash/logstash:7.16.2
COPY logstash/logstash.yml /usr/share/logstash/config/logstash.yml
COPY logstash/logstash.conf /usr/share/logstash/pipeline/logstash.conf 
USER root
RUN chown logstash:root /usr/share/logstash/config/logstash.yml
RUN chown logstash:root /usr/share/logstash/pipeline/logstash.conf 
USER logstash
CMD logstash