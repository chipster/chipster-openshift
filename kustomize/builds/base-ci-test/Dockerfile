FROM base-java-utils

# CI tests need both Java and NodeJS
# TODO how to copy node from base-node ta avoid installing it twice?
RUN apt-get update -y \
	&& apt-get install -y build-essential \
	&& curl -sL https://deb.nodesource.com/setup_20.x | bash - \
	&& apt-get install -y nodejs \
	&& npm config set update-notifier false \
	&& apt-get clean

RUN ls -lah /opt/chipster || true \
	&& ls -lah /opt/chipster/tools || true \
	&& ls -lah /opt/chipster/js || true

CMD ["sleep", "inf"]
