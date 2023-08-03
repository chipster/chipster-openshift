FROM base-node

COPY . /tmp/build/chipster-web-server/

# build typescript server components
# config.ts assumes it's running in the js/type-service folder when it's finding the configs
# remove .npm directory to avoid file permission problems (see also ../base-node/Dockerfile)
RUN cd /tmp/build/chipster-web-server/js/type-service \
	&& npm install \
	&& npm run build \
	&& rm -rf /home/user/.npm
	
RUN cd /tmp/build/chipster-web-server/js/type-service \
	&& mkdir -p /opt/chipster/js/type-service/src \
	&& mv src/*.js /opt/chipster/js/type-service/src \
	&& mv *.json /opt/chipster/js/type-service/ \
	&& mv node_modules /opt/chipster/js/type-service \
	&& mkdir -p /opt/chipster/src/main/resources \
	&& mv /tmp/build/chipster-web-server/src/main/resources/chipster-defaults.yaml /opt/chipster/src/main/resources/ \
 	&& chmod -R ugo+rwx /opt/chipster \
 	&& rm -rf /tmp/build/chipster-web-server

WORKDIR /opt/chipster/js/type-service

CMD npm start
