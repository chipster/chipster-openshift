FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates adduser libfontconfig1 \
  && rm -rf /var/lib/apt/lists/*
# the package depends on libfontconfig, which is called libfontconfig1 in newer Ubuntu versions
RUN wget -q https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_5.0.1_amd64.deb \
  && echo "9f691c58c3cb723147da59d88f334f029d42df5189747c6fbd224127d47fbd60  grafana_5.0.1_amd64.deb" | sha256sum -c - \
  && dpkg -i --ignore-depends=libfontconfig grafana_5.0.1_amd64.deb \
  && rm grafana_5.0.1_amd64.deb

RUN chmod -R a+rwx /var/lib
RUN chmod -R a+rwx /var/log

CMD cd /usr/share/grafana ; /usr/sbin/grafana-server
