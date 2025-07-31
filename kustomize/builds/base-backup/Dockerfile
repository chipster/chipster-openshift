# runtime base image for java components

FROM base-java-24-04

RUN install -d /usr/share/postgresql-common/pgdg \
	&& curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
	&& sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
	&& apt-get update \
	&& apt-get install -y postgresql-client-14 postgresql-contrib-14 \
	&& apt-get install -y gnupg2 \	
	&& apt-get clean 

# only needed in file-storage backup restore instructions, which we don't use anymore
# && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
# && unzip awscliv2.zip \
# && ./aws/install \

CMD sleep inf




