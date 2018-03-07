# we need the manuals from the chipster-tools repo
FROM toolbox

# copy the client code repo
COPY . /home/user/build/chipster-web

# /opt/chipster-web is created by the manual copy in the toolbox build and /home/user/build is created by the copy above  
RUN mkdir -p /opt/chipster-web/src \
	&& chmod ugo+rwx -R /home/user/build /opt/chipster-web
	
USER 1000

# remove the symlink becasue ng build doesn't tolerate it
# the source image already has to manual in place 
RUN cd /home/user/build/chipster-web \	
	&& npm install \
	&& rm src/assets/manual \
	&& ng build --prod --no-progress || true \
	&& cp -r dist/* /opt/chipster-web/src/ \
	&& ls -lah /opt/chipster-web/src/ \
	&& rm -rf /home/user/build

CMD ["java", "-XX:+UseSerialGC", "-XX:+TieredCompilation", "-XX:TieredStopAtLevel=1", "-XX:MinHeapFreeRatio=20", "-XX:MaxHeapFreeRatio=40", "-XX:GCTimeRatio=4", "-XX:AdaptiveSizePolicyWeight=90", "-Xss228k", "-Xms32m", "-Xmx128m","-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
