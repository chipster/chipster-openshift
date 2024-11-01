FROM base-ci-test

COPY chipster-web-server /home/user/
COPY tools /home/user/chipster-web-server/

RUN ls -lah /home/user || true \
	&& ls -lah /home/user/chipster-web-server || true \
	&& ls -lah /home/user/chipster-web-server/tools || true

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.rest.ServerLauncher"]
