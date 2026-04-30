FROM base-24-04

RUN apt-get update -y \
	&& apt-get install -y software-properties-common apt-transport-https \
	&& wget -O- https://apt.corretto.aws/corretto.key | apt-key add - \
	&& add-apt-repository 'deb https://apt.corretto.aws stable main' \
	&& apt-get install -y java-25-amazon-corretto-jdk \
	&& apt-get clean

CMD sleep inf