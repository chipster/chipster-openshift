FROM base

USER 0

RUN mkdir -p /opt/chipster \
&& ln -s /mnt/artefacts/chipster-tools-bin/${CHIPSTER_TOOLS_BIN_BUILD:-latest} /opt/chipster/tools

RUN mkdir -p /opt/chipster-web-server \
&& ln -s /mnt/artefacts/chipster-web-server/${CHIPSTER_WEB_SERVER_BUILD:-latest} /opt/chipster-web-server/lib
RUN ln -s /mnt/artefacts/chipster-web/${CHIPSTER_WEB_BUILD:-latest}/chipster-web /opt/chipster-web
RUN ln -s /mnt/artefacts/chipster-tools/${CHIPSTER_TOOLS_BUILD:-latest}/chipster-tools /opt/chipster-tools

RUN ls -lah /opt/chipster-web-server

RUN chmod -R ugo+rwx /opt

USER 1001

EXPOSE 8080

WORKDIR /opt/chipster-web-server

ENTRYPOINT ["java", "-cp",  "lib/*:"]  
CMD ["fi.csc.chipster.rest.ServerLauncher"]

