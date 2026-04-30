FROM comp-24-04-r-deps

# install python3, pip and venv for cutadapt
RUN apt update -y \ 
  && apt install -y \
  libjpeg-turbo8-dev \
  python3 \
  python3-pip \
  python3.12-venv \
  && apt-get clean

RUN mkdir -p /opt/chipster/tools \
  && curl -s https://a3s.fi/bundle-builds/R-4.4.3-asv_2025-03-17.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools

RUN mkdir -p /opt/chipster/tools/cutadapt/venv \
  && python3 -m venv /opt/chipster/tools/cutadapt/venv \
  && . /opt/chipster/tools/cutadapt/venv/bin/activate \
  && pip3 install cutadapt

CMD ["sleep", "inf"]
