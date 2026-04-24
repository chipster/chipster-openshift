FROM base-node

COPY chipster-web-server /home/user/

RUN cd /home/user/chipster-web-server/js/cli-client \
    && chmod -R ug+rwx .

# npm ci --omit=dev does not install dev dependencies. gitlab-ci-audit.yml assumes this also
RUN cd /home/user/chipster-web-server/js/cli-client \
    && npm ci --omit=dev; npx tsc

WORKDIR /home/user/chipster-web-server/js/cli-client

CMD node lib/benchmark -h