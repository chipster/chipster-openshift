FROM base-ci-test

COPY chipster-web-server /home/user/
COPY tools /home/user/chipster-web-server/

WORKDIR /home/user/chipster-web-server

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.rest.ServerLauncher"]
