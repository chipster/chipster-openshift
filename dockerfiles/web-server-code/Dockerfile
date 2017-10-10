FROM chipster-web-server

# install before COPY so that this layer can be cached
# install the angular-cli also locally to speed up dependency installation later
RUN mkdir -p /tmp/build/home /tmp/build/chipster-web /opt/chipster-web \
	&& chmod ugo+rwx -R /tmp/build /opt/chipster-web \
	&& HOME=/tmp/build/home \
	&& cd /tmp/build/chipster-web \
	&& npm install -g @angular/cli \
	&& npm install -g bower \
	&& npm install @angular/cli

COPY . /tmp/build/chipster-web

# the copied files have too strict permissions
RUN chmod ugo+rwx -R /tmp/build

USER 1000

# the assets forlder isn't copied in ng build, probably because the "manual" symlink in it is broken at this point
# copy assets separately  
RUN cd /tmp/build/chipster-web \
	&& HOME=/tmp/build/home \
	&& sed -i "/export const ServiceLocator/c\export const ServiceLocator = '${SERVICE_LOCATOR}';" src/assets/app.constants.ts \	
	&& npm install \
	&& ng -v \
	&& ng build || true \	
	&& cp -r dist/* /opt/chipster-web/ \
	&& cp -r src/assets /opt/chipster-web/ \	
	&& rm -rf /tmp/build/*
	

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
