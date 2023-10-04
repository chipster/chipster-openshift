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
&& apt-get clean

RUN rm /opt/chipster/tools \
&& mkdir -p /opt/chipster/tools \
&& curl -s https://a3s.fi/bundle-builds/R-4.3.1-single-cell_2023-09-21.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools \
&& mkdir /opt/chipster/tools/seurat \
&& curl -s https://a3s.fi/bundle-builds/seurat_regev_lab_cell_cycle_genes_2023-09-21.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools/seurat

CMD ["sleep", "inf"]
