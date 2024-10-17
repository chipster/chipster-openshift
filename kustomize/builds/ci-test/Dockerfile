FROM web-server

COPY tools /opt/chipster/tools
COPY js /opt/chipster

RUN ls -lah /opt/chipster || true \
	&& ls -lah /opt/chipster/tools || true \
	&& ls -lah /opt/chipster/js || true

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.rest.ServerLauncher"]
