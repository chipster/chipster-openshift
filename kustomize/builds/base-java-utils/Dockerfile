FROM base-java-24-04

RUN apt-get update -y \
	&& apt-get install -y gradle gnupg2 \
	&& curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
	&& unzip awscliv2.zip \
	&& ./aws/install \
	&& mkdir -p /etc/apt/keyrings \
	&& curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
	&& echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
	&& apt-get update -y \
	&& apt-get install -y kubectl \
	&& wget --quiet https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq \
	&& chmod +x /usr/bin/yq \
	&& apt-get install -y curl ca-certificates \
	&& install -d /usr/share/postgresql-common/pgdg \
	&& curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
	&& sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
	&& apt-get update \
	&& apt-get install -y postgresql-client-14 postgresql-contrib-14 \
	&& apt-get clean

CMD sleep inf




