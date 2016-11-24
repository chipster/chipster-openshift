FROM chipster-web-server

COPY . /tmp/build/chipster-web

RUN cd /tmp/build/chipster-web \
	&& sed -i "/export const ServiceLocator/c\export const ServiceLocator = '${SERVICE_LOCATOR}';" src/app/app.constants.ts \
	&& npm install \
	&& ng build || true \
	&& mkdir -p /opt/chipster-web \
	&& cp -r dist/* /opt/chipster-web/ \
	&& rm -rf /tmp/build/chipster-web

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
