FROM java:8

RUN apt-get update
RUN apt-get install -y ant

RUN groupadd -r chipster && useradd -r -g chipster -u 1001 chipster

WORKDIR /home/chipster
RUN mkdir -p /opt/chipster-web-server/lib

RUN chown -R chipster:chipster /home/chipster
RUN chown -R chipster:chipster /opt

USER 1001

# clone main projects to the home dir for building
RUN git clone --branch ${CHIPSTER_BRANCH:-openshift} https://github.com/chipster/chipster.git --depth=1

# build the old chipster project
RUN cd chipster; ant package-jar
RUN cp chipster/dist/chipster-*.jar /opt/chipster-web-server/lib


