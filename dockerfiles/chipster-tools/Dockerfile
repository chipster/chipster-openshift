FROM chipster-web-server

USER 0

RUN mkdir /opt/chipster-tools && chmod ugo+rwx /opt/chipster-tools

USER 1001

# no need to build these projects, clone directly to /opt
RUN cd /opt; git clone --branch ${TOOLS_BRANCH:-openshift} --single-branch https://github.com/chipster/chipster-tools.git --depth=1

WORKDIR /opt/chipster-web-server

CMD java -cp lib/*: ${JAVA_CLASS}

