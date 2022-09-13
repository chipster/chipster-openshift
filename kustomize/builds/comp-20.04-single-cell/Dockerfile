FROM comp-20.04-r-deps

RUN apt update -y \ 
&& apt install -y \
libhdf5-dev \
libgeos-dev \
pkg-config \
libfftw3-dev \
&& apt-get clean

CMD ["sleep", "inf"]
