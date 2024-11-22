FROM base-ci-test

COPY chipster-web-server /home/user/
COPY chipster-tools /home/user/
COPY chipster-web-app /home/user/

WORKDIR /home/user/chipster-web-server

# install JFrog CLI
RUN curl -fL https://install-cli.jfrog.io | sh

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.rest.ServerLauncher"]
