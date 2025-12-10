FROM comp-r-4-5-1

RUN mkdir /opt/chipster/tools/fastx \
    && cd /opt/chipster/tools/fastx \
    && wget http://hannonlab.cshl.edu/fastx_toolkit/fastx_toolkit_0.0.13_binaries_Linux_2.6_amd64.tar.bz2 \
    && tar -xvjf fastx_toolkit_0.0.13_binaries_Linux_2.6_amd64.tar.bz2 \
    && rm fastx_toolkit_0.0.13_binaries_Linux_2.6_amd64.tar.bz2 \
    && bin/fastq_to_fasta -h

CMD ["sleep", "inf"]
