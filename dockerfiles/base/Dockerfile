FROM ubuntu:14.04

# install Oracle java, because openjdk installation fails in a container

RUN apt-get update \
#&& apt-get -y install python-software-properties \
# accept Oracle's license \
#&& echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
#&& add-apt-repository ppa:webupd8team/java \
#&& apt-get update \
#&& apt-get install -y oracle-java8-installer

# all in one RUN command to avoid extra image layers
RUN apt-get install -y openjdk-8-jdk git ant gradle nano dstat pv wget unzip \
# update all packages \
&& apt-get upgrade \
# remove old java versions \
#&& apt-get purge -y openjdk-6-* \
#&& apt-get purge -y openjdk-7-* \
# don't store the apt-get cache to the image \
&& apt-get clean

#RUN update-java-alternatives --list
#RUN update-java-alternatives -s java-1.8.0-openjdk-amd64

CMD sleep inf