FROM base-java-comp

COPY chipster-web-server-build /opt/

RUN mkdir -p /opt/chipster \
  && chmod -R ugo+rwx /opt/chipster \
  && cd /opt/chipster \
  && ln -s /mnt/tools tools \
  && ls -lah /opt/chipster

WORKDIR /opt/chipster

CMD ["sleep", "inf"]
