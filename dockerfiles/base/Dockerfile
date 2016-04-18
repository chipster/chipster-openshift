FROM centos:7

# all in one RUN command to avoid extra image layers
# update all packages \
RUN yum upgrade \
&& yum install -y openjdk-8-jdk git ant gradle nano dstat pv wget unzip \
&& yum clean all

CMD sleep inf