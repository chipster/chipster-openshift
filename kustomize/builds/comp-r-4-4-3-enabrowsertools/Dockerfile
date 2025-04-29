FROM comp-r-4-4-3

RUN mkdir /tmp/enabrowsertools \
    && cd /tmp/enabrowsertools \
    && wget https://github.com/enasequence/enaBrowserTools/archive/refs/tags/v1.7.1.tar.gz \
    && tar xzf v1.7.1.tar.gz -C /opt/chipster/tools \
    && rm -rf /tmp/enabrowsertools \
    && cd /opt/chipster/tools \
    && ln -s enaBrowserTools-1.7.1 enabrowsertools

CMD ["sleep", "inf"]
