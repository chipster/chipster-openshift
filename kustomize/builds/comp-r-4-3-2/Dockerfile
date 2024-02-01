FROM comp-20-04-r-deps

RUN rm /opt/chipster/tools \
&& mkdir -p /opt/chipster/tools \
&& curl -s https://a3s.fi/bundle-builds/R-4.3.2_2023-12-07.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools

CMD ["sleep", "inf"]
