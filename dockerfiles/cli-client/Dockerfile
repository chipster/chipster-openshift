FROM base

COPY . /home/user/chipster-web-server/

RUN cd /home/user/chipster-web-server/js/cli-client \
    && chmod -R ugo+rwx . \    
	&& npm install; tsc

WORKDIR /home/user/chipster-web-server/js/cli-client

CMD node src/benchmark -h