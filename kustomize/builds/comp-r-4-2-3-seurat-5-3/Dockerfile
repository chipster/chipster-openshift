FROM comp-20-04-r-deps

RUN apt update -y \ 
    && apt install -y \
    libhdf5-dev \
    libgeos-dev \
    pkg-config \
    libfftw3-dev \
    libgsl-dev \
    libfontconfig1-dev \
    libcairo2-dev \
    libxt-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libtiff5-dev \
    libglpk-dev \
    git \
    && apt-get clean

RUN mkdir -p /opt/chipster/tools \
    && curl -s https://a3s.fi/bundle-builds/R-4.2.3-seurat5_2025-07-22.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools \
    && mkdir /opt/chipster/tools/seurat \
    && curl -s https://a3s.fi/bundle-builds/seurat_regev_lab_cell_cycle_genes_2023-09-21.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools/seurat


## added in R-4.2.3-seurat5_2025-07-22.tar.lz4
# RUN cd tools/R-4.2.3/bin; \
#     ./R -e 'install.packages("ggplot2", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("patchwork", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("hdf5r", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("arrow", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("Seurat", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'

CMD ["sleep", "inf"]
