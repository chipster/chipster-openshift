FROM chipster-web-server

USER 0

# all in one RUN command to avoid extra image layers
RUN \ 
# enable the backports repository \
&& add-apt-repository 'deb http://nova.clouds.archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse' \
# all the packages from the VM \
&& apt-get install -y openjdk-8-jre openjdk-8-jdk ghostscript fastx-toolkit python-pip python-numpy python-matplotlib python-zsi cython libgd2-noxpm-dev python3-yaml libgfortran3 libcurl3 libglib2.0-0 libglu1-mesa libgsl0ldbl libpng12-0 libreadline6 libxml2 mesa-common-dev tcl tk xorg-dev unixodbc gawk libnetcdf6 build-essential gfortran libcurl4-openssl-dev libglib2.0-dev libglu1-mesa-dev libgsl0-dev libpng-dev libreadline-dev libxml2-dev mesa-common-dev tcl-dev tk-dev xorg-dev python-dev unixodbc-dev libnetcdf-dev git ant libjson-perl libcairo-perl libtext-simpletable-perl libcontextual-return-perl libwant-perl libhttp-parser-perl cpanminus unzip pigz pbzip2 dstat xfsprogs emacs23 tree nfs-common python-pip parallel curl rsync \
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

