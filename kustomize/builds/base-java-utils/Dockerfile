# runtime base image for java components

FROM base-java-24-04

RUN apt-get update -y \
	&& apt-get install -y gnupg2 \	
	&& mkdir -p /etc/apt/keyrings \
	&& curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
	&& echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
	&& apt-get update -y \
	&& apt-get install -y kubectl \
	&& wget --quiet https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq \
	&& chmod +x /usr/bin/yq \
	&& apt-get clean 

# only needed in file-storage backup restore instructions, which we don't use anymore
# TODO add warning to the instructions and notify email list
# && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
# && unzip awscliv2.zip \
# && ./aws/install \

CMD sleep inf




