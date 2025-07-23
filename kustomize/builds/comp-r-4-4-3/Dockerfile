FROM comp-24-04-r-deps

# this is minimal image, but install the command "file", because it's used in many 
# tools to check if gzip files should be extracted
RUN rm /opt/chipster/tools \
    && mkdir -p /opt/chipster/tools \
    && curl -s https://a3s.fi/bundle-builds/R-4.4.3_2025-03-14.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools \
    && apt update -y \ 
    && apt install -y \
    file \
    && apt-get clean

CMD ["sleep", "inf"]
