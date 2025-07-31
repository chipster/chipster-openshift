FROM base-java-20-04

# build arg for build version, because envs are not configurable directly
ARG ARG_CHIPSTER_BUILD_VERSION=""
# Chipster config can get values from envs
ENV chipster_build_version=${ARG_CHIPSTER_BUILD_VERSION}

COPY chipster-web-server-build /

RUN mkdir -p /opt/chipster \
  && chmod -R ugo+rwx /opt/chipster \
  && cd /opt/chipster \
  && ln -s /mnt/tools tools \
  && ls -lah /opt/chipster

WORKDIR /opt/chipster

CMD ["sleep", "inf"]
