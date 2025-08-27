FROM comp-24-04-r-deps

# install python3, pip and venv for cutadapt
RUN apt update -y \ 
    && apt install -y \
    libjpeg-turbo8-dev \
    python3 \
    python3-pip \
    python3.12-venv \
    && apt-get clean

RUN rm /opt/chipster/tools \
    && mkdir -p /opt/chipster/tools \
    && curl -s https://a3s.fi/bundle-builds/R-4.5.1-asv_2025-08-07.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools

RUN mkdir -p /opt/chipster/tools/cutadapt/venv \
  && python3 -m venv /opt/chipster/tools/cutadapt/venv \
  && . /opt/chipster/tools/cutadapt/venv/bin/activate \
  && pip3 install cutadapt

# installed in R-4.5.1-asv_2025-08-07.tar.lz4
# RUN rm /opt/chipster/tools \
#     && mkdir -p /opt/chipster/tools \
#     && curl -s https://a3s.fi/bundle-builds/R-4.5.1_2025-08-07.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools
# # 13 min, dada2_1.36.0
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'install.packages("BiocManager", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'BiocManager::install("dada2", version = "3.21")'

CMD ["sleep", "inf"]
