FROM base

COPY . /tmp/build/chipster-web-server/

# build typescript server components
# config.ts assumes it's running in  src/main/javascript folders when it's finding the configs
RUN cd /tmp/build/chipster-web-server/src/main/javascript \
	&& npm install \
	&& tsc *.ts || true \
	&& mkdir -p /opt/chipster-web-server/src/main/javascript \
	&& mv *.js /opt/chipster-web-server/src/main/javascript \
	&& mv node_modules /opt/chipster-web-server/src/main/javascript \
	&& mv /tmp/build/chipster-web-server/conf /opt/chipster-web-server/ \
 	&& chmod -R ugo+rwx /opt/chipster-web-server \
 	&& rm -rf /tmp/build/chipster-web-server

WORKDIR /opt/chipster-web-server/src/main/javascript

CMD node ${JS_FILE:-type-service.js}
