FROM comp-20-04-r-deps

RUN ls -lah /opt/chipster/tools

RUN rm /opt/chipster/tools; mkdir -p /opt/chipster/tools; curl -s https://a3s.fi/bundle-builds/R-4.2.3_2023-04-13.tar.lz4 | lz4 -d | tar x -C /opt/chipster/tools

CMD ["sleep", "inf"]
