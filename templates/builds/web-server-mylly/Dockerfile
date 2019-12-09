FROM chipster-web-server

COPY chipster-web /opt/chipster
COPY mylly-tools-manual /opt/chipster/chipster-web/assets

RUN mv /opt/chipster/chipster-web /opt/chipster/web-root \
	&& chmod ugo+rwx -R /opt/chipster/web-root \
	&& ls -lah /opt/chipster/web-root \
	&& ls -lah /opt/chipster/web-root/assets \
	&& ls -lah /opt/chipster/web-root/assets/manual

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
