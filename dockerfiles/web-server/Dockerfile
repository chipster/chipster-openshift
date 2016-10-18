FROM chipster-web-server

COPY . /tmp/build/chipster-web

RUN cd /tmp/build/chipster-web \
	&& sed -i "/export const ServiceLocator/c\export const ServiceLocator = '${SERVICE_LOCATOR}';" app/app.constants.ts \
	&& npm install \
	&& (npm run tsc --silent || true) \
	&& mkdir -p /opt/chipster-web \
	&& cp -r * /opt/chipster-web/ \
	&& rm -rf /tmp/build/chipster-web

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
