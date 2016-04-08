FROM base

WORKDIR /tmp/src

RUN mkdir -p /opt/chipster-web-server/lib

# clone main projects to the tmp dir for building
RUN git clone --single-branch ${CHIPSTER_BRANCH:-openshift} https://github.com/chipster/chipster.git --depth=1

# build the old chipster project
RUN cd chipster; ant package-jar ; cp chipster/dist/chipster-*.jar /opt/chipster-web-server/lib ; rm -rf /tmp/src/chipster


