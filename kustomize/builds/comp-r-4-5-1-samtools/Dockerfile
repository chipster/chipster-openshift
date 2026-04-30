FROM comp-r-4-5-1

RUN cd /opt/chipster/tools \
    && wget https://github.com/samtools/samtools/releases/download/1.22.1/samtools-1.22.1.tar.bz2 \
    && tar -xvf samtools-1.22.1.tar.bz2 \
    && rm samtools-1.22.1.tar.bz2 \
    && cd samtools-1.22.1 \    
    && ./configure --prefix=/opt/chipster/tools/samtools \
    && make \
    && make install \
    && cd .. \
    && rm -rf samtools-1.22.1 \
    && wget https://github.com/samtools/bcftools/releases/download/1.22/bcftools-1.22.tar.bz2 \
    && tar -xvf bcftools-1.22.tar.bz2 \
    && rm bcftools-1.22.tar.bz2 \
    && cd bcftools-1.22 \    
    && ./configure --prefix=/opt/chipster/tools/bcftools \
    && make \
    && make install \
    && cd .. \
    && rm -rf bcftools-1.22

CMD ["sleep", "inf"]
