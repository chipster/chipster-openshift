FROM base

USER 0

RUN mkdir -p /opt/chipster && ln -s /mnt/artefacts/chipster-tools-bin/${CHIPSTER_TOOLS_BIN_BUILD:-latest} tools
RUN mkdir -p /opt/chipster-web-server && ln -s /mnt/artefacts/chipster-web-server/${CHIPSTER_WEB_SERVER_BUILD:-latest} lib
RUN ln -s /mnt/artefacts/chipster-web/${CHIPSTER_WEB_BUILD:-latest} /opt/chipster-web
RUN ln -s /mnt/artefacts/chipster-tools/${CHIPSTER_TOOLS_BUILD:-latest} /opt/chipster-tools

RUN chmod -R ugo+rwx /opt

USER 1001

EXPOSE 8080

WORKDIR /opt/chipster-web-server  
CMD java -cp lib/*: ${JAVA_CLASS:-fi.csc.chipster.rest.ServerLauncher}

