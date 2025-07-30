# runtime base image for java components

FROM base-java-24-04

RUN apt-get update -y \
	&& apt-get install -y gnupg2 \	
	&& apt-get clean 

# only needed in file-storage backup restore instructions, which we don't use anymore
# && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
# && unzip awscliv2.zip \
# && ./aws/install \

CMD sleep inf




