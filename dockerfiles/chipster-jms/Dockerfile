FROM base

WORKDIR /tmp/src

RUN mkdir -p /opt/chipster/lib

# clone main projects to the tmp dir for building
RUN git clone --branch ${CHIPSTER_BRANCH:-openshift} --single-branch https://github.com/chipster/chipster.git --depth=1

# build the old chipster project
RUN cd chipster; ant package-jar ; cp dist/chipster-*.jar /opt/chipster-web-server/lib ; rm -rf /tmp/src/chipster


