FROM comp-r-4-4-3

RUN apt update -y \ 
    && apt install -y \
    libjpeg-turbo8-dev \
    && apt-get clean

RUN cd tools/R-4.4.3/bin; \
    ./R -e 'install.packages("BiocManager", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
    ./R -e 'BiocManager::install("dada2")'

CMD ["sleep", "inf"]
