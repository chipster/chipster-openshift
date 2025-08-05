FROM comp-24-04

# packages for R
# libssl-dev, libpng-dev and libxml2-dev required by Seurat and DESeq2, but probably by many other packages too
# rsync for tools-bin builds in k3s
# "file" for tools to check file types (e.g. is the file gzip or not)
RUN apt update -y \ 
    && apt install -y \
    build-essential \
    gfortran \
    libreadline-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libpcre3-dev \
    libssl-dev \
    libpng-dev \
    libxml2-dev \
    rsync \
    file \
    && apt-get clean

CMD ["sleep", "inf"]
