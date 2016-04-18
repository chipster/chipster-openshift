FROM centos:7

# all in one RUN command to avoid extra image layers
# update all packages \
RUN yum upgrade -y \
&& yum install -y java-1.8.0-openjdk git ant gradle nano dstat pv wget unzip \
&& yum clean all

# there is no gradle package in centos7
RUN mkdir -p /opt && cd /opt \
&& wget https://services.gradle.org/distributions/gradle-2.13-rc-1-bin.zip -O gradle.zip \
&& unzip gradle.zip \
&& ln -s gradle-* gradle && rm gradle.zip
ENV GRADLE_PATH=/opt/gradle/bin
ENV PATH=$PATH:$GRADLE_PATH

CMD sleep inf