# use Python 3.8 in Ubuntu 20.04, because enaBrowserTools apparently isn't 
# compatible with Python 3.12 in Ubuntu 24.04: SyntaxWarning: invalid escape sequence '\.'
FROM comp-r-4-3-2

RUN mkdir /tmp/enabrowsertools \
    && cd /tmp/enabrowsertools \
    && wget https://github.com/enasequence/enaBrowserTools/archive/refs/tags/v1.7.1.tar.gz \
    && tar xzf v1.7.1.tar.gz -C /opt/chipster/tools \
    && rm -rf /tmp/enabrowsertools \
    && cd /opt/chipster/tools \
    && ln -s enaBrowserTools-1.7.1 enabrowsertools

CMD ["sleep", "inf"]
