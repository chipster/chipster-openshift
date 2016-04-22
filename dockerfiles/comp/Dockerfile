FROM base

RUN apt-get update -y \ 
&& apt-get install -y \  
#openjdk-8-jre \
#openjdk-8-jdk \
ghostscript \
fastx-toolkit \
python-pip \
python-numpy \
python-matplotlib \
python-zsi \
cython \
libgd2-noxpm-dev \
python3-yaml \
libgfortran3 \
libcurl3 \
libglib2.0-0 \
libglu1-mesa \
libgsl0ldbl \
libpng12-0 \
libreadline6 \
libxml2 \
mesa-common-dev \
tcl \
tk \
xorg-dev \
unixodbc \
gawk \
libnetcdf6 \
build-essential \
gfortran \
libcurl4-openssl-dev \
libglib2.0-dev \
libglu1-mesa-dev \
libgsl0-dev \
libpng-dev \
libreadline-dev \
libxml2-dev \
mesa-common-dev \
tcl-dev \
tk-dev \
xorg-dev \
python-dev \
unixodbc-dev \
libnetcdf-dev \
git \
ant \
libjson-perl \
libcairo-perl \
libtext-simpletable-perl \
libcontextual-return-perl \
libwant-perl \
libhttp-parser-perl \
cpanminus \
unzip \
pigz \
pbzip2 \
dstat \
xfsprogs \
emacs23 \
tree \
#nfs-common \
python-pip \
parallel \
curl \
rsync \
&& apt-get clean

WORKDIR /opt/chipster-web-server

USER 1001

CMD java -cp lib/*: fi.csc.chipster.comp.CompServer
