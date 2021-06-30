FROM chipster-web-server

RUN apt-get update -y \ 
&& apt-get install -y \  
python3 \
# python3-pip \
# python3-matplotlib \
# cython \
# python3-yaml \
# python-dev \
&& apt-get clean

CMD ["java", "-cp", "lib/*:", "-Xmx512m", "fi.csc.chipster.comp.SingleShotComp"]
