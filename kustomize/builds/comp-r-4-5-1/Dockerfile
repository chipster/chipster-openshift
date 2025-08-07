FROM comp-24-04-r-deps

RUN rm /opt/chipster/tools \
    && mkdir -p /opt/chipster/tools \
    && curl -s https://a3s.fi/bundle-builds/R-4.5.1_2025-08-07.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools

# installed in R-4.5.1_2025-08-07.tar.lz4
# RUN rm /opt/chipster/tools \
#     && mkdir -p tools/temp \
#     && cd tools/temp \
#     && wget https://ftp.acc.umu.se/mirror/CRAN/src/base/R-4/R-4.5.1.tar.gz \
#     && tar -xzf R-4.5.1.tar.gz \
#     && cd R-4.5.1 \
#     && ./configure --with-x=no --with-pcre1 --prefix=/opt/chipster/tools/R-4.5.1 \
#     && make \
#     && make install \
#     && du -sh /opt/chipster/tools/*

CMD ["sleep", "inf"]
