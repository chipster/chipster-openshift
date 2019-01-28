FROM openshift/jenkins-2-centos7

USER 0

RUN yum install -y bc \
	&& yum install epel-release -y \
	&& yum install -y python-pip \
	&& yum install -y jq \
	&& yum clean all \
	&& pip install yq	
	