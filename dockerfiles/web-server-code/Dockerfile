FROM chipster-web-server

# copy the git repo
COPY . /home/user/build/chipster-web

# create directory for the server and give permissions for writing in there and in the build dir 
RUN mkdir -p /opt/chipster-web \
	&& chmod ugo+rwx -R /home/user/build /opt/chipster-web
	
USER 1000

# remove the symlink before ng build and create a correct one after it, becasue ng build doesn't tolerate it
RUN cd /home/user/build/chipster-web \
	&& sed -i "/export const ServiceLocator/c\export const ServiceLocator = '${SERVICE_LOCATOR}';" src/assets/app.constants.ts \	
	&& npm install \
	&& rm src/assets/manual \
	&& ng build --no-progress || true \
	&& ln -s /opt/chipster-tools/manual dist/assets/manual \
	&& cp -r dist/* /opt/chipster-web/ \	
	&& rm -rf /home/user/build

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
