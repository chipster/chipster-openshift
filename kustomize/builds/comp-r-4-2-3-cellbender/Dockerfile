FROM comp-r-4-2-3

RUN ls -lah /opt/chipster/tools

# there should be no need to specify fixed versions, because R-4.2.3 should install 
# only BiocManager version 3.16, which again should install only rhdf5 version 2.42.1
# rhdf5 needed to post-process h5 files be compatible with Seurat 4
RUN cd tools/R-4.2.3/bin; \
    ./R -e 'install.packages("BiocManager", repos = "https://ftp.acc.umu.se/mirror/CRAN/")'; \
    ./R -e 'BiocManager::install("rhdf5")'

CMD ["sleep", "inf"]
