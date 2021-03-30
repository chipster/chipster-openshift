FROM chipster-web-server

COPY chipster-web /opt/chipster
# copy html separately so that the BuildConfig can be patched to take it from another image
COPY html /opt/chipster/chipster-web/assets
COPY manual /opt/chipster/chipster-web/assets

RUN mv /opt/chipster/chipster-web /opt/chipster/web-root \	
	&& chmod ugo+rwx -R /opt/chipster/web-root \
	&& ls -lah /opt/chipster/web-root || true \
	&& ls -lah /opt/chipster/web-root/assets || true \
	&& ls -lah /opt/chipster/web-root/assets/manual | head || true \
	&& ls -lah /opt/chipster/web-root/assets/html || true

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
