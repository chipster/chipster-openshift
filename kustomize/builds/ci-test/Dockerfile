FROM web-server

COPY tools /opt/chipster/tools
COPY js /opt/chipster/js

RUN apt-get update -y \
	&& apt-get install -y build-essential \
	&& curl -sL https://deb.nodesource.com/setup_20.x | bash - \
	&& apt-get install -y nodejs \
	&& npm config set update-notifier false \
	&& apt-get clean

RUN ls -lah /opt/chipster || true \
	&& ls -lah /opt/chipster/tools || true \
	&& ls -lah /opt/chipster/js || true

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.rest.ServerLauncher"]
