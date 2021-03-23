FROM base-java-comp

COPY chipster-web-server /opt/

RUN mkdir -p /opt/chipster/comp \
  && chmod -R ugo+rwx /opt/chipster \
  && cd /opt/chipster \
  && ln -s /mnt/tools tools \
  && ls -lah /opt/chipster

WORKDIR /opt/chipster/comp

CMD ["java", "-cp", "../lib/*:", "-Xmx512m", "fi.csc.chipster.comp.RestCompServer"]
