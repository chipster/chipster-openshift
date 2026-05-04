FROM base-node

COPY chipster-web-server /home/user/

RUN cd /home/user/chipster-web-server/js/cli-client \
    && chmod -R ug+rwx .

# Run first "npm ci" to install with dev dependecies, because tsc requires typescript.
# Then use --omit=dev to remove dev dependencies. gitlab-ci-audit.yml assumes that those are removed.
# Use --ignore-scripts because "npm ci" triggers the "prepare" script, which requires dev dependencies and we want to omit them. It's good also for safety.
RUN cd /home/user/chipster-web-server/js/cli-client \
    && npm ci --ignore-scripts \
    && npx tsc \
    && npm ci --omit=dev  --ignore-scripts

WORKDIR /home/user/chipster-web-server/js/cli-client

CMD node lib/benchmark -h