FROM ubuntu:24.04

WORKDIR /home/user

ENV HOME=/home/user

# set timezone, because dstat package depends on tzdata, which tries to ask it interactively
RUN apt-get update -y \
	&& ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime && echo "Etc/UTC" > /etc/timezone \
	&& apt-get upgrade -y

RUN apt-get install -y nano

RUN apt-get install -y dstat

RUN apt-get install -y pv

RUN apt-get install -y curl

RUN apt-get install -y liblz4-tool

RUN apt-get install -y parallel

RUN apt-get install -y jq

RUN apt-get install -y wget

RUN apt-get install -y rsync

RUN apt-get install -y less

RUN apt-get clean \
	&& chmod ug+rwx $HOME

# OpenShift gives a random uid for the user and some programs (e.g. dstat) try to find a username from the /etc/passwd.
# Let user to fix it, but obviously this shouldn't be run outside OpenShift
RUN chmod ug+rw /etc/passwd \
	&& echo 'echo "chipster:x:$(id -u):$(id -g)::/tmp:/bin/bash" >> /etc/passwd' > fix-username.bash

CMD sleep inf