FROM base-node

COPY chipster-web-server /home/user/

RUN cd /home/user/chipster-web-server/js/cli-client \
    && chmod -R ug+rwx .

# Run first "npm ci" to install with dev dependecies, because tsc requires typescript.
# Then use --omit=dev to remove dev dependencies. gitlab-ci-audit.yml assumes that those are removed.
RUN cd /home/user/chipster-web-server/js/cli-client \
    && npm ci \
    && npx tsc \
    && npm ci --omit=dev

WORKDIR /home/user/chipster-web-server/js/cli-client

CMD node lib/benchmark -h