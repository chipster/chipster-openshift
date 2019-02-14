FROM openshift/jenkins-2-centos7

USER 0

RUN yum install -y bc \
	&& yum install epel-release -y \
	&& yum install -y jq \
	&& yum clean all \
	&& curl -L https://github.com/mikefarah/yq/releases/download/2.2.1/yq_linux_amd64 > /bin/yq \
	&& chmod ugo+x /bin/yq
	