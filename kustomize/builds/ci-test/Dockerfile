FROM web-server

COPY tools /opt/chipster/tools

RUN ls -lah /opt/chipster || true \
	&& ls -lah /opt/chipster/tools || true

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.rest.ServerLauncher"]
