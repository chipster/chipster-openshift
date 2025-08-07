FROM comp-24-04-r-deps

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

RUN rm /opt/chipster/tools \
    && mkdir -p /opt/chipster/tools \
    && curl -s https://a3s.fi/bundle-builds/R-4.5.1-seurat5_2025-08-07.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools \
    && mkdir -p /opt/chipster/tools/seurat \
    && curl -s https://a3s.fi/bundle-builds/seurat_regev_lab_cell_cycle_genes_2023-09-21.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools/seurat

# installed in R-4.5.1-seurat5_2025-08-07.tar.lz4

# # minimal R
# RUN curl -s https://a3s.fi/bundle-builds/R-4.5.1_2025-08-07.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools

# # these are needed to install some packages
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'install.packages("BiocManager", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("remotes", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'

# # slow to install
# # 21 min
# # setRepositories: "Seurat does not require, but makes use of, packages developed by other labs that can substantially enhance speed and performance"
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'install.packages("Seurat", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'setRepositories(ind = 1:3, addURLs = c("https://satijalab.r-universe.dev", "https://bnprks.r-universe.dev/"))'

# # 1 s
# # BPCells requires "apt-get install -y libhdf5-dev"
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'install.packages(c("BPCells", "presto", "glmGamPoi"), repos = "https://ftp.acc.umu.se/mirror/CRAN/")'

# # packages which required manually installed dependencies
# # scater requires r-lib/systemfonts
# # metap requires multtest
# # 14 min
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'remotes::install_github("r-lib/systemfonts")'; \
#     ./R -e 'BiocManager::install("scater")'; \
#     ./R -e 'BiocManager::install("multtest")'; \
#     ./R -e 'install.packages("metap", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'

# # 12 min
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'install.packages("Rfast2", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'

# # BiocManager
# # limma is a more efficient implementation of the Wilcoxon Rank Sum Test for e.g. single-cell-seurat-diffexp-samples.R
# # 14 min
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'BiocManager::install("DESeq2")'; \
#     ./R -e 'BiocManager::install("glmGamPoi")'; \
#     ./R -e 'BiocManager::install("GEOquery")'; \
#     ./R -e 'BiocManager::install("celldex")'; \
#     ./R -e 'BiocManager::install("MAST")'; \
#     ./R -e 'BiocManager::install("SingleR")'; \
#     ./R -e 'BiocManager::install("mvoutlier")'; \
#     ./R -e 'BiocManager::install("limma")'

# # remotes, 1 min
# # install SCDC from pull request, because fix for NA values has not bee released yet
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'remotes::install_github("renozao/xbioc")'; \
#     ./R -e 'remotes::install_github("meichendong/SCDC", ref = remotes::github_pull("31"))'

# # relatively fast to install
# # 10 min
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'install.packages("Matrix", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("umap", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("dplyr", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("pheatmap", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("gplots", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("cowplot", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("ggplot2", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("tidyr", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("hdf5r", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("devtools", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("ggrepel", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("tidyverse", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("patchwork", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'install.packages("arrow", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'

# # schard requires apt install git
# # 13 s
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'install.packages("devtools", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'devtools::install_github("cellgeni/schard")'

# # 2024-02-29: latest version 1.2.0 fails in spatial-transcriptomics-seurat-sctransform-v5.R with "Error: useNames = NA is defunct. Instead, specify either useNames = TRUE or useNames = FALSE."
# # 5 s
# RUN cd tools/R-4.5.1/bin; \
#     ./R -e 'remotes::install_version("matrixStats", version="1.1.0", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'    

CMD ["sleep", "inf"]
