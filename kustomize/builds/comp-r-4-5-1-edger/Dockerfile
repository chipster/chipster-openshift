FROM comp-r-4-5-1

# try to load the package to check if installation was successful
RUN cd tools/R-4.5.1/bin; \
    ./R -e 'install.packages("BiocManager", repos = "https://ftp.acc.umu.se/mirror/CRAN/")' \
    ./R -e 'BiocManager::install("edgeR")' \
    ./R -e 'library("edgeR")'

CMD ["sleep", "inf"]
