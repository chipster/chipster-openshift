FROM ubuntu:16.04

# install apache, shibd and java
RUN apt update -y \
	&& apt install -y shibboleth-sp2-common libapache2-mod-shib2 apache2 shibboleth-sp2-utils openjdk-8-jdk gradle \
	&& apt clean

# create a separate dir for relevant shibd confs so that we don't hide other files when we mount a secret volume over it
# and allow shibd to write to /var 	
RUN mkdir /etc/shibboleth/secret \
	&& cd /etc/shibboleth \
	&& cp shibboleth2.xml secret/shibboleth2.xml \
	&& mv shibboleth2.xml shibboleth2.xml.original \
	&& mv attribute-map.xml attribute-map.xml.original \
	&& ln -s secret/shibboleth2.xml shibboleth2.xml \
	&& ln -s secret/attribute-map.xml attribute-map.xml \
	&& mkdir -p /var/run/shibboleth /var/cache/shibboleth /var/log/shibboleth \
	&& chgrp -R root /var/run/shibboleth /var/cache/shibboleth /var/log/shibboleth \
	&& chmod -R g+w /var/run/shibboleth /var/cache/shibboleth /var/log/shibboleth
	
# allow apache to write to these directories and disable the binding to port 80 because it would require root permissions
RUN chgrp -R root /var/log/apache2/ /var/lock/apache2/ /var/run/apache2/ \
	&& chmod -R g+w /var/log/apache2/ /var/lock/apache2/ /var/run/apache2/ \
	&& mv /etc/apache2/ports.conf /etc/apache2/ports.conf.original \
	&& echo "Listen 8000" > /etc/apache2/sites-enabled/shibboleth.conf \
	&& touch /etc/apache2/ports.conf	

CMD ["bash", "-c", "/etc/init.d/apache2 start; shibd -F start"]