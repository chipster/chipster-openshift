FROM base-16-04

RUN apt-get update -y \
	&& apt-get install -y software-properties-common apt-transport-https \
	&& wget -O- https://apt.corretto.aws/corretto.key | apt-key add - \
 	&& add-apt-repository 'deb https://apt.corretto.aws stable main' \
	&& apt-get update -y \ 
	&& apt-get install -y java-11-amazon-corretto-jdk gradle postgresql-client postgresql-contrib gnupg2 awscli \
	&& apt-get clean

CMD sleep inf