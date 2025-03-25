FROM comp-24-04-r-deps

RUN apt update -y \ 
    && apt install -y \
    cmake \
    && apt-get clean

RUN rm /opt/chipster/tools \
    && mkdir -p /opt/chipster/tools \
    && curl -s https://a3s.fi/bundle-builds/R-4.4.3-phyloseq_2025-03-25.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools

CMD ["sleep", "inf"]
