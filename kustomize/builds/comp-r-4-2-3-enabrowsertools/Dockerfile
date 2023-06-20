FROM comp-r-4-2-3

# download this specific commit, because the latest release version 1.5.4 from 2020 tries to use deprecated ssl v1
RUN COMMIT="43799babcf2cbbc530d4e85ef2b0370c8bf876e6" \
&& mkdir /tmp/enabrowsertools \
&& cd /tmp/enabrowsertools \
&& wget https://github.com/enasequence/enaBrowserTools/archive/$COMMIT.tar.gz -O enabrowsertools.tar.gz \
&& tar xzf enabrowsertools.tar.gz -C /opt/chipster/tools \
&& rm -rf /tmp/enabrowsertools \
&& cd /opt/chipster/tools \
&& ln -s enaBrowserTools-$COMMIT enabrowsertools

CMD ["sleep", "inf"]
