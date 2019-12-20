FROM base

RUN apt-get update -y \
	&& apt-get install -y software-properties-common \
	&& add-apt-repository -y ppa:openjdk-r/ppa \
	&& apt-get update -y \ 
	&& apt-get install -y openjdk-11-jdk-headless gradle postgresql-client postgresql-contrib gnupg2 awscli \
	&& apt-get clean

CMD sleep inf