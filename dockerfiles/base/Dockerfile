#FROM centos:7
FROM ubuntu:16.04

# all in one RUN command to avoid extra image layers
# update all packages \
#RUN yum upgrade -y \
#&& yum install -y java-1.8.0-openjdk git ant gradle nano dstat pv wget unzip which \
#&& yum clean all

RUN apt-get udpate -y \ 
&& apt-get upgrade -y \
&& apt-get install -y openjdk-8-jdk git ant gradle nano dstat pv wget unzip which \
&& apt-get clean

# there is no gradle package in centos7
RUN mkdir -p /opt && cd /opt \
&& wget https://services.gradle.org/distributions/gradle-2.13-rc-1-bin.zip -O gradle.zip \
&& unzip gradle.zip \
&& ln -s gradle-* gradle && rm gradle.zip
ENV GRADLE_PATH=/opt/gradle/bin
ENV PATH=$PATH:$GRADLE_PATH

CMD sleep inf