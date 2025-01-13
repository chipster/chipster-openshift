FROM base-java-utils

# build arg for build version, because envs are not configurable directly
ARG ARG_CHIPSTER_BUILD_VERSION=""
# Chipster config can get values from envs
ENV chipster_build_version=${ARG_CHIPSTER_BUILD_VERSION}

COPY . /home/user/chipster-web-server

WORKDIR /home/user/chipster-web-server

CMD ["sleep", "inf"]
