FROM java:8

RUN apt-get update
RUN apt-get install -y ant nano netcat dstat mbuffer pv && apt-get clean

# install gradle manually, because the apt-get package depends on Java 7
RUN mkdir -p /opt && cd /opt && wget https://services.gradle.org/distributions/gradle-2.13-rc-1-bin.zip -O gradle.zip && unzip gradle.zip && ln -s gradle-* gradle && rm gradle.zip
ENV GRADLE_PATH=/opt/gradle/bin
ENV PATH=$PATH:$GRADLE_PATH
ENV TERM=xterm

#RUN update-java-alternatives --list
#RUN update-java-alternatives -s java-1.8.0-openjdk-amd64

CMD sleep inf