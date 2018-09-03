FROM base

COPY . /tmp/build/chipster-web-server/

# build typescript server components
# config.ts assumes it's running in the js/type-service folder when it's finding the configs
RUN cd /tmp/build/chipster-web-server/js/type-service \
	&& npm install \
	&& npm run build \
	&& mkdir -p /opt/chipster-web-server/js/type-service/src \
	&& mv src/*.js /opt/chipster-web-server/js/type-service/src \
	&& mv *.json /opt/chipster-web-server/js/type-service/ \
	&& mv node_modules /opt/chipster-web-server/js/type-service \
	&& mv /tmp/build/chipster-web-server/conf /opt/chipster-web-server/ \
 	&& chmod -R ugo+rwx /opt/chipster-web-server \
 	&& rm -rf /tmp/build/chipster-web-server

WORKDIR /opt/chipster-web-server/js/type-service

CMD npm start
