FROM chipster-web-server

USER 0

# all in one RUN command to avoid extra image layers
RUN \ 
# enable the backports repository \
#add-apt-repository 'deb http://nova.clouds.archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse' \
&& apt-get update \
# all the packages from the VM \
&& apt-get install -y ghostscript \
&& apt-get install -y fastx-toolkit \
&& apt-get install -y python-pip \
&& apt-get install -y python-numpyv
&& apt-get install -y python-matplotlib \
&& apt-get install -y python-zsi \
&& apt-get install -y cython \
&& apt-get install -y libgd2-noxpm-dev \
&& apt-get install -y python3-yaml \
&& apt-get install -y libgfortran3 \
&& apt-get install -y libcurl3 \
&& apt-get install -y libglib2.0-0 \
&& apt-get install -y libglu1-mesa \
&& apt-get install -y libgsl0ldbl \
&& apt-get install -y libpng12-0 \
&& apt-get install -y libreadline6 \
&& apt-get install -y libxml2 \
&& apt-get install -y mesa-common-dev \
&& apt-get install -y tcl \
&& apt-get install -y tk \
&& apt-get install -y xorg-dev \
&& apt-get install -y unixodbc \
&& apt-get install -y gawk \
&& apt-get install -y libnetcdf6 \
&& apt-get install -y build-essential \
&& apt-get install -y gfortran \
&& apt-get install -y libcurl4-openssl-dev \
&& apt-get install -y libglib2.0-dev \
&& apt-get install -y libglu1-mesa-dev \
&& apt-get install -y libgsl0-dev \
&& apt-get install -y libpng-dev \
&& apt-get install -y libreadline-dev \
&& apt-get install -y libxml2-dev \
&& apt-get install -y mesa-common-dev \
&& apt-get install -y tcl-dev \
&& apt-get install -y tk-dev \
&& apt-get install -y xorg-dev \
&& apt-get install -y python-dev \
&& apt-get install -y unixodbc-dev \
&& apt-get install -y libnetcdf-dev \
&& apt-get install -y libjson-perl \
&& apt-get install -y libcairo-perl \
&& apt-get install -y libtext-simpletable-perl \
&& apt-get install -y libcontextual-return-perl \
&& apt-get install -y libwant-perl \
&& apt-get install -y libhttp-parser-perl \
&& apt-get install -y cpanminus \
&& apt-get install -y pigz \
&& apt-get install -y pbzip2 \
&& apt-get install -y dstat \
&& apt-get install -y xfsprogs \
&& apt-get install -y emacs23 \
&& apt-get install -y tree \
&& apt-get install -y python-pip \
&& apt-get install -y parallel \
&& apt-get install -y curl \
&& apt-get install -y rsync
&& apt-get clean

# update all packages \
&& apt-get upgrade \
# don't store the apt-get cache into the image \
&& apt-get clean

RUN mkdir /opt/chipster-tools && chmod ugo+rwx /opt/chipster-tools

# no need to build these projects, clone directly to /opt
RUN cd /opt; git clone --branch ${TOOLS_BRANCH:-openshift} --single-branch https://github.com/chipster/chipster-tools.git --depth=1 && rm -rf chipster-tools/.git

WORKDIR /opt/chipster-web-server

USER 1001

CMD java -cp lib/*: ${JAVA_CLASS}

