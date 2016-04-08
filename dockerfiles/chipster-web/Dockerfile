FROM java:8

RUN mkdir /opt/chipster-web
RUN chown -R chipster:chipster /opt/chipster-*

USER 1001

# no need to build these projects, clone directly to /opt
RUN cd /opt; git clone --branch ${CLIENT_BRANCH:-openshift} https://github.com/chipster/chipster-web.git --depth=1

WORKDIR /opt/chipster-web-server  

CMD java -cp lib/*: fi.csc.chipster.web.WebServer
