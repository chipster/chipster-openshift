FROM chipster-web-server

USER 0

RUN mkdir /opt/chipster-web && chmod ugo+rwx /opt/chipster-web

# no need to build these projects, clone directly to /opt
RUN cd /opt; git clone --branch ${CLIENT_BRANCH:-openshift} --single-branch https://github.com/chipster/chipster-web.git --depth=1

USER 1001

WORKDIR /opt/chipster-web-server  

CMD java -cp lib/*: fi.csc.chipster.web.WebServer
