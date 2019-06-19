FROM docker.elastic.co/logstash/logstash:7.1.1
COPY chipster-openshift/logstash/logstash.yml /usr/share/logstash/config/logstash.yml
COPY chipster-openshift/logstash/logstash.conf /usr/share/logstash/pipeline/logstash.conf 
USER root
RUN chown root:logstash /usr/share/logstash/config/logstash.yml
RUN chown root:logstash /usr/share/logstash/pipeline/logstash.conf 
USER logstash
CMD logstash
