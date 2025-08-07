FROM comp-20-04-r-deps

RUN rm /opt/chipster/tools \
    && mkdir -p /opt/chipster/tools \
    && curl -s https://a3s.fi/bundle-builds/R-4.2.3-cellbender_2025-08-07.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools

# installed in R-4.2.3-cellbender_2025-08-07.tar.lz4

# FROM comp-r-4-2-3

# # there should be no need to specify fixed versions, because R-4.2.3 should install 
# # only BiocManager version 3.16, which again should install only rhdf5 version 2.42.1
# # rhdf5 needed to post-process h5 files be compatible with Seurat 4
# RUN cd tools/R-4.2.3/bin; \
#     ./R -e 'install.packages("BiocManager", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
#     ./R -e 'BiocManager::install("rhdf5")'

CMD ["sleep", "inf"]
