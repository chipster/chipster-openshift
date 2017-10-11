# we need the manuals from the chipster-tools repo
FROM toolbox

# copy the client code repo
COPY . /home/user/build/chipster-web

# /opt/chipster-web is created by the manual copy in the toolbox build and /home/user/build is created by the copy above  
RUN chmod ugo+rwx -R /home/user/build /opt/chipster-web
	
USER 1000

# remove the symlink becasue ng build doesn't tolerate it
# the source image already has to manual in place 
RUN cd /home/user/build/chipster-web \
	&& sed -i "/export const ServiceLocator/c\export const ServiceLocator = '${SERVICE_LOCATOR}';" src/assets/app.constants.ts \	
	&& npm install \
	&& rm src/assets/manual \
	&& ng build --no-progress || true \
	&& cp -r dist/* /opt/chipster-web/ \	
	&& rm -rf /home/user/build

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
