FROM base-java

RUN apt-get update -y \
	&& curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
	&& echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list \
	&& apt-get update -y \ 
	&& apt-get install -y gradle postgresql-client postgresql-contrib gnupg2 awscli kubectl \
	&& apt-get clean

CMD sleep inf