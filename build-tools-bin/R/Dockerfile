FROM base
  
# dependencies of the R itself
RUN apt-get build-dep -y r-base-dev \
&& apt-get clean

# dependencies of the R libs
RUN apt-get install -y libxml2-dev mesa-common-dev libssl-dev gsl-bin libglu1-mesa-dev \
&& apt-get clean
