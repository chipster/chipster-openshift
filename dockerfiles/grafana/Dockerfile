FROM ubuntu:16.04

RUN apt-get update && apt-get install -y wget
RUN wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_5.0.1_amd64.deb
RUN apt-get install -y adduser libfontconfig
RUN dpkg -i grafana_5.0.1_amd64.deb

RUN chmod -R a+rwx /var/lib
RUN chmod -R a+rwx /var/log

CMD cd /usr/share/grafana ; /usr/sbin/grafana-server