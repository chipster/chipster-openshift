FROM base-20-04


# set timezone, because java installation tries to ask it interactively
RUN apt-get update -y \
	&& ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime && echo "Etc/UTC" > /etc/timezone \
	&& apt-get install -y software-properties-common apt-transport-https \
	&& wget -O- https://apt.corretto.aws/corretto.key | apt-key add - \
	&& add-apt-repository 'deb https://apt.corretto.aws stable main' \
	&& apt-get update -y \ 
	&& apt-get install -y java-21-amazon-corretto-jdk \
	&& apt-get clean

CMD sleep inf