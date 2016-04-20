FROM base
 
# install R build dependencies 
# R itself
RUN apt-get build-dep -y r-base-dev \
# R libs
RUN apt-get install -y libxml2-dev \
&& apt-get clean
