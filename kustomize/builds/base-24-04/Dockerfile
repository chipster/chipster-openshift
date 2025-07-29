FROM ubuntu:24.04

WORKDIR /home/user

ENV HOME=/home/user

RUN apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install -y nano pv curl liblz4-tool parallel jq wget rsync less \
	&& apt-get clean \
	&& chmod ug+rwx $HOME

CMD sleep inf