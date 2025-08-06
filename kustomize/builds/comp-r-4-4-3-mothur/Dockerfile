FROM comp-24-04-r-deps

RUN ls -lah /opt/chipster/tools \
    && rm -rf /opt/chipster/tools \
    && mkdir -p /opt/chipster/tools \
    && curl -s https://a3s.fi/bundle-builds/R-4.4.3-mothur_2025-08-05.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools \
    && apt update -y \ 
    && apt install -y \
    unzip \
    && apt-get clean \
    && cd /opt/chipster/tools \
    && wget -nv https://github.com/mothur/mothur/releases/download/v1.48.2/Mothur.Ubuntu_22.zip \
    && unzip Mothur.Ubuntu_22.zip \
    && rm Mothur.Ubuntu_22.zip \
    && ls -lah

# installed in R-4.4.3-mothur_2025-08-05.tar.lz4
# RUN cd tools/R-4.4.3/bin; \
#     ./R -e 'install.packages("reshape2", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'

CMD ["sleep", "inf"]
