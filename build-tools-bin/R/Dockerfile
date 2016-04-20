FROM base
  
# dependencies of the R itself
RUN apt-get build-dep -y r-base-dev \
&& apt-get clean

# dependencies of the R libs
RUN apt-get install -y libxml2-dev mesa-common-dev \
&& apt-get clean
