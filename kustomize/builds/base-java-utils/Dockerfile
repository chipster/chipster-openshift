FROM base-java

RUN apt-get update -y \
	&& apt-get install -y gradle gnupg2 \
	&& curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
	&& unzip awscliv2.zip \
	&& ./aws/install \
	&& mkdir /etc/apt/keyrings \
	&& curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
	&& echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
	&& apt-get update -y \
	&& apt-get install -y kubectl \
	&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64 \
	&& add-apt-repository ppa:rmescandon/yq \
	&& apt-get update -y \
	&& apt-get install -y yq \
	&& echo 'deb http://apt.postgresql.org/pub/repos/apt focal-pgdg main' | tee /etc/apt/sources.list.d/pgdg.list \
	&& wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
	&& apt-get update \
	&& apt-get install -y postgresql-client-14 postgresql-contrib-14 \
	&& apt-get clean

CMD sleep inf




