# base image for java builds
# install build tools (like gradle) that shouldn't be in the runtime image

FROM base-java-24-04

# gradle from apt-get is old (4.4.1 from 2017). We'll use sdkman to get the latest version
# sdkman installation needs unzip and zip
RUN apt-get update -y \
	&& apt-get install -y unzip zip \	
	&& apt-get clean \
	&& curl -s "https://get.sdkman.io?ci=true" | bash \
	&& bash -c 'source ~/.sdkman/bin/sdkman-init.sh; sdk install gradle'

CMD sleep inf
