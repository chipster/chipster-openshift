FROM base-ci-test

COPY chipster-web-server /home/user/chipster-web-server
COPY tools /home/user/chipster-web-server/tools

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.rest.ServerLauncher"]
