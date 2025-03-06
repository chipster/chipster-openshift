FROM ubuntu:24.04

WORKDIR /home/user

ENV HOME=/home/user

# set timezone, otherwise dstat package depend on tzdata, which tries to ask it interactively
RUN apt-get update -y \
	&& ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime && echo "Etc/UTC" > /etc/timezone \
	&& apt-get upgrade -y \
	&& apt-get install -y nano dstat pv curl liblz4-tool parallel jq wget rsync less \
	&& apt-get clean \
	&& chmod ug+rwx $HOME

CMD sleep inf