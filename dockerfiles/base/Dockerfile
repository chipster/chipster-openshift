FROM ubuntu:12.04

# Fake a fuse install https://gist.github.com/henrik-muehe/6155333
RUN apt-get install libfuse2 \
&& cd /tmp ; apt-get download fuse \
&& cd /tmp ; dpkg-deb -x fuse_* . \
&& cd /tmp ; dpkg-deb -e fuse_* \
&& cd /tmp ; rm fuse_*.deb \
&& cd /tmp ; echo -en '#!/bin/bash\nexit 0\n' > DEBIAN/postinst \
&& cd /tmp ; dpkg-deb -b . /fuse.deb \
&& cd /tmp ; dpkg -i /fuse.deb

# all in one RUN command to avoid extra image layers
RUN apt-get update \
# install the add-apt-repository command \
&& apt-get install -y python-software-properties \
# add a java repository \
&& add-apt-repository 'ppa:openjdk-r/ppa' \
&& apt-get update \
# install some generic tools
&& apt-get install -y nano dstat pv wget unzip openjdk-8-jdk openjdk-8-jre \
# update all packages \
&& apt-get upgrade \
# remove old java versions \
&& apt-get purge -y openjdk-6-* \
&& apt-get purge -y openjdk-7-* \
# don't store the apt-get cache to the image \
&& apt-get clean

# install ant from binaries, because the apt-get package depends on openjdk-6
RUN mkdir -p /opt && cd /opt \
&& wget http://www-us.apache.org/dist//ant/binaries/apache-ant-1.9.7-bin.tar.gz -O ant.tar.gz \
&& tar -zxf ant.tar.gz
ENV ANT_HOME=/opt/ant
ENV PATH=$PATH:$ANT_HOME/bin 

# install git from sources, because package installation fails in ubuntu:12.04 container
RUN apt-get install -y libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev build-essential
RUN mkdir -p /opt && cd /opt \
&& wget https://git-core.googlecode.com/files/git-1.8.1.2.tar.gz -O git.tar.gz \
&& tar -zxf git.tar.gz \
&& ln -s git-* git \
&& cd git \
&& make prefix=/usr/local all \
&& make prefix=/usr/local install 

# install gradle from binaries, because package installation fails in ubuntu:12.04 container
RUN mkdir -p /opt && cd /opt \
&& wget https://services.gradle.org/distributions/gradle-2.13-rc-1-bin.zip -O gradle.zip \
&& unzip gradle.zip \
&& ln -s gradle-* gradle && rm gradle.zip

ENV GRADLE_PATH=/opt/gradle/bin
ENV PATH=$PATH:$GRADLE_PATH
ENV TERM=xterm

#RUN update-java-alternatives --list
#RUN update-java-alternatives -s java-1.8.0-openjdk-amd64

CMD sleep inf