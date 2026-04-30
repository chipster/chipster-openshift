# runtime image for scheduler (with kubectl and yq)

FROM base-scheduler

# build arg for build version, because envs are not configurable directly
ARG ARG_CHIPSTER_BUILD_VERSION=""
# Chipster config can get values from envs
ENV chipster_build_version=${ARG_CHIPSTER_BUILD_VERSION}

COPY chipster-web-server-build /

WORKDIR /opt/chipster

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.scheduler.Scheduler"]
