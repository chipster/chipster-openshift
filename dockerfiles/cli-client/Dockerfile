FROM base

COPY . /home/user/chipster-web-server/

RUN cd /home/user/chipster-web-server/js/cli-client \
    && chmod -R ugo+rwx .
    
USER 1000
RUN cd /home/user/chipster-web-server/js/cli-client \
	&& npm install; tsc

WORKDIR /home/user/chipster-web-server/js/cli-client

CMD node lib/benchmark -h