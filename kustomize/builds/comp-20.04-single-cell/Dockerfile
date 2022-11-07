FROM comp-20.04-r-deps

RUN apt update -y \ 
&& apt install -y \
libhdf5-dev \
libgeos-dev \
pkg-config \
libfftw3-dev \
libgsl-dev \
&& apt-get clean

CMD ["sleep", "inf"]
