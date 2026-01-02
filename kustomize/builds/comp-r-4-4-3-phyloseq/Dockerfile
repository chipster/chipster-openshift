FROM comp-24-04-r-deps

# ghostscript "gs" is used in some tools to combine pdf files in the end
RUN apt update -y \ 
    && apt install -y \
    cmake \
    ghostscript \
    && apt-get clean

RUN rm /opt/chipster/tools \
    && mkdir -p /opt/chipster/tools \
    && curl -s https://a3s.fi/bundle-builds/R-4.4.3-phyloseq_2025-03-25.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools

# deseq2-pca-heatmap.R
RUN cd tools/R-4.4.3/bin; \
    ./R -e 'install.packages("gplots", repos = "https://ftp.acc.umu.se/mirror/CRAN/")' \
    ./R -e 'install.packages("RColorBrewer", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'

CMD ["sleep", "inf"]
