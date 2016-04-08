FROM java:8

RUN apt-get update
RUN apt-get install -y ant && apt-get clean

RUN groupadd -r chipster && useradd -r -g chipster -u 1001 chipster

WORKDIR /home/chipster
RUN mkdir -p /opt/chipster-web-server/lib

RUN chown -R chipster:chipster /home/chipster
RUN chown -R chipster:chipster /opt

USER 1001
