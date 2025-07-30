FROM base-20-04

RUN apt-get update -y \
	&& apt-get install -y software-properties-common apt-transport-https \
	&& wget -O- https://apt.corretto.aws/corretto.key | apt-key add - \
	&& add-apt-repository 'deb https://apt.corretto.aws stable main' \
	&& apt-get update -y \ 
	&& apt-get install -y java-21-amazon-corretto-jdk \
	&& apt-get clean

CMD sleep inf