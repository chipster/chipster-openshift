FROM base-java

RUN apt-get update -y \
	&& apt-get install -y gradle postgresql-client postgresql-contrib gnupg2 awscli jq \
	&& mkdir /etc/apt/keyrings \
	&& curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
	&& echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
	&& apt-get update -y \ 
	&& apt-get install -y kubectl \
	&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64 \
	&& add-apt-repository ppa:rmescandon/yq \
	&& apt-get update -y \ 
	&& apt-get install -y yq \
	&& apt-get clean

CMD sleep inf