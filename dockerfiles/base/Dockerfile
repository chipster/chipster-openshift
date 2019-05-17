FROM ubuntu:16.04

#&& apt-get install -y openjdk-8-jdk git ant gradle nano dstat pv wget unzip bzip2 curl build-essential liblz4-tool parallel tmux jq nmap ldap-utils apache2-utils postgresql-client postgresql-contrib \

RUN apt-get update -y
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:openjdk-r/ppa

# openjdk packages should be in this order to make 11 default
RUN apt-get update -y \ 
	&& apt-get upgrade -y \
	&& apt-get install -y openjdk-11-jdk-headless openjdk-8-jdk ant gradle nano dstat pv curl build-essential liblz4-tool parallel jq postgresql-client postgresql-contrib gnupg2 awscli \
	&& curl -sL https://deb.nodesource.com/setup_8.x | bash - \
	&& apt-get install -y nodejs \
	&& apt-get clean

# OpenShift gives a random uid for the user and some programs (e.g. dstat) try to find a username from the /etc/passwd.
# Let user to fix it, but obviously this shouldn't be run outside OpenShift
RUN chmod ug+rw /etc/passwd \
	&& echo 'echo "chipster:x:$(id -u):$(id -g)::/tmp:/bin/bash" >> /etc/passwd' > fix-username.bash

WORKDIR /home/user

ENV HOME=/home/user

RUN chmod ug+rwx $HOME \
	&& npm install -g typescript \
	&& npm install -g @angular/cli \
	&& npm cache clean --force

#RUN which nodejs \
#	&& ng -v \
#	&& which npm \
#	&& which tsc \
#	&& which ng \
#	&& npm config get prefix	

CMD sleep inf