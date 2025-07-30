# runtime image for java components

FROM base-java-utils

# build arg for build version, because envs are not configurable directly
ARG ARG_CHIPSTER_BUILD_VERSION=""
# Chipster config can get values from envs
ENV chipster_build_version=${ARG_CHIPSTER_BUILD_VERSION}

COPY chipster-web-server-build /opt/

WORKDIR /opt/chipster

CMD java -cp lib/*:  ${JAVA_CLASS:-fi.csc.chipster.rest.ServerLauncher}
