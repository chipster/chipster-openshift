FROM chipster-web-server

RUN apt-get update -y \ 
	&& apt-get install -y python-pip python3-setuptools python3-dev \
	&& apt-get clean \
	&& easy_install3 pip

# what is using this .cache?
RUN mkdir -p /home/user/.cache \
  && chown $(whoami) /home/user/.cache \
  && mkdir -p /homeappl \
  && ln -s /appl /homeappl/appl_taito
  
RUN curl -s https://korp.csc.fi/download/.mylly/kielipankki_local_root_install.sh | sed 's/pip /pip2 /g' | bash

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.comp.RestCompServer"]
