FROM chipster-web-server

RUN apt-get update -y \ 
	&& apt-get install -y python-pip python3-setuptools python3-dev \
	&& apt-get clean \
	&& easy_install3 pip

RUN mkdir -p /opt/chipster/comp \
  && chmod -R ugo+rwx /opt/chipster-web-server \
  && cp -r /opt/chipster-web-server/lib /opt/chipster \
  && mkdir -p /opt/chipster/comp/security \
  && mkdir -p /home/user/.cache \
  && chown $(whoami) /home/user/.cache \
  && mkdir -p /homeappl \
  && ln -s /appl /homeappl/appl_taito
  
RUN curl -s https://korp.csc.fi/download/.mylly/kielipankki_local_root_install.sh | sed 's/pip /pip2 /g' | bash
  
# Legacy DirectoryLayout assumes it's running here
WORKDIR /opt/chipster/comp

USER 0

CMD ["java", "-cp", "../lib/*:", "fi.csc.chipster.comp.RestCompServer"]
