FROM java:8

RUN apt-get update
RUN apt-get install -y ant gradle && apt-get clean

#RUN update-java-alternatives --list

RUN update-java-alternatives -s java-1.8.0-openjdk-amd64
