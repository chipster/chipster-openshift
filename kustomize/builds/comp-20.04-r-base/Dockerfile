FROM comp-20.04

RUN apt update -y \ 
&& apt install -y \
build-essential \
gfortran \
libreadline-dev \
libcurl4-openssl-dev \
zlib1g-dev \
libbz2-dev \
liblzma-dev \
libpcre3-dev \
&& apt-get clean

# The following commands were used to build R to tools-bin
# 
# cd /opt/chipster/tools/temp
# wget https://ftp.acc.umu.se/mirror/CRAN/src/base/R-4/R-4.1.1.tar.gz
# tar -xzf R-4.1.1.tar.gz
# cd R-4.1.1
# ./configure --with-x=no --with-pcre1 --prefix=/opt/chipster/tools/R-4.1.1
# make
# make install

CMD ["sleep", "inf"]
