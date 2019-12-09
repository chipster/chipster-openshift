FROM base

# installation of node-gyb npm package expects the program "make" from the build-essential package
RUN apt-get update -y \
	&& apt-get install -y build-essential \
	&& curl -sL https://deb.nodesource.com/setup_8.x | bash - \
	&& apt-get install -y nodejs \
	&& apt-get clean

RUN npm install -g typescript \
	&& npm install -g @angular/cli \
	&& npm cache clean --force

#RUN which nodejs \
#	&& ng -v \
#	&& which npm \
#	&& which tsc \
#	&& which ng \
#	&& npm config get prefix	

CMD sleep inf