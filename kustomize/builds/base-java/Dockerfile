FROM base

# set timezone, otherwise one of these packages depend on tzdata, which tries to ask it interactively
RUN apt-get update -y \
    && ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime && echo "Etc/UTC" > /etc/timezone \
	&& apt-get install -y software-properties-common apt-transport-https \
	&& wget -O- https://apt.corretto.aws/corretto.key | apt-key add - \
 	&& add-apt-repository 'deb https://apt.corretto.aws stable main' \
	&& curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
	&& echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list \
	&& apt-get update -y \ 
	&& apt-get install -y java-11-amazon-corretto-jdk gradle postgresql-client postgresql-contrib gnupg2 awscli kubectl \
	&& apt-get clean

CMD sleep inf