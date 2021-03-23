FROM chipster-web-server

COPY chipster-web /opt/chipster
COPY manual /opt/chipster/chipster-web/assets
COPY chipster-csc /home/user

RUN mv /opt/chipster/chipster-web /opt/chipster/web-root \
	&& ls -lah /home/user \
	&& ls -lah /home/user/chipster-csc \		
	&& mv /home/user/chipster-csc/html/* /opt/chipster/web-root/assets/html/ \
	&& chmod ugo+rwx -R /opt/chipster/web-root \
	&& ls -lah /opt/chipster/web-root || true \
	&& ls -lah /opt/chipster/web-root/assets || true \
	&& ls -lah /opt/chipster/web-root/assets/manual || true \
	&& ls -lah /opt/chipster/web-root/assets/html || true

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
