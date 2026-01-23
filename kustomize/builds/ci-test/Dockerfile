FROM base-ci-test

COPY chipster-web-server /home/user/
COPY chipster-tools /home/user/
COPY chipster-web-app /home/user/

WORKDIR /home/user/chipster-web-server

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.rest.ServerLauncher"]
