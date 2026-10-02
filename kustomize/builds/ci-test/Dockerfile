FROM base-ci-test

COPY chipster-web-server /home/user/
COPY chipster-tools /home/user/
COPY chipster-web-app /home/user/

WORKDIR /home/user/chipster-web-server

# The tests run with the default service passwords, which auth refuses to start with otherwise.
# This is the configuration key auth-allow-default-passwords in chipster-defaults.yaml, in the
# environment variable form that Config reads. ENV rather than CMD, because the pipeline that
# runs this image is not in this repository, so the command it uses is unknown.
ENV auth_allow_default_passwords=true

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.rest.ServerLauncher"]
