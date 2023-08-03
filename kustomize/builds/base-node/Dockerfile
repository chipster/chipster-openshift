FROM base

# installation of node-gyb npm package expects the program "make" from the build-essential package
# disable update-notifier. Otherwise node doesn't start a week after the image build, because the .npm is directory was created by root. As a side effect node refuses to start immediately, if the root-owned .npm directory exists, but you can simply delete it.
RUN apt-get update -y \
	&& apt-get install -y build-essential \
	&& curl -sL https://deb.nodesource.com/setup_16.x | bash - \
	&& apt-get install -y nodejs \
	&& npm config set update-notifier false \
	&& apt-get clean

RUN npm install -g typescript \
	&& npm install -g @angular/cli \	
	&& npm cache clean --force \
	&& rm -rf /home/user/.npm

#RUN which nodejs \
#	&& ng -v \
#	&& which npm \
#	&& which tsc \
#	&& which ng \
#	&& npm config get prefix	

CMD sleep inf