FROM ubuntu:16.04

RUN apt-get update -y \ 
&& apt-get upgrade -y \
&& apt-get install -y openjdk-8-jdk git ant gradle nano dstat pv wget unzip bzip2 curl build-essential liblz4-tool parallel tmux jq\
&& curl -sL https://deb.nodesource.com/setup_7.x | bash - \
&& apt-get install -y nodejs \
&& apt-get clean \
&& npm install -g typescript

# OpenShift gives a random uid for the user and some programs (e.g. dstat) try to find a username from the /etc/passwd.
# Let user to fix it, but obviously this shouldn't be run outside OpenShift
RUN chmod ug+rw /etc/passwd \
 && echo 'echo "chipster:x:$(id -u):$(id -g)::/tmp:/bin/bash" >> /etc/passwd' > fix-username.bash

WORKDIR /home/user

CMD sleep inf