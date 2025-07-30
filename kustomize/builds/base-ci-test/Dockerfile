FROM base-java-utils

# CI tests need both Java and NodeJS
# TODO how to copy node from base-node ta avoid installing it twice?
# also psql is needed to create the databases for the tests
RUN apt-get update -y \
	&& apt-get install -y build-essential \
	&& curl -sL https://deb.nodesource.com/setup_20.x | bash - \
	&& apt-get install -y nodejs \
	&& npm config set update-notifier false \
	&& install -d /usr/share/postgresql-common/pgdg \
	&& curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
	&& sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
	&& apt-get update \
	&& apt-get install -y postgresql-client-14 postgresql-contrib-14 \
	&& apt-get clean


RUN ls -lah /opt/chipster || true \
	&& ls -lah /opt/chipster/tools || true \
	&& ls -lah /opt/chipster/js || true

CMD ["sleep", "inf"]
