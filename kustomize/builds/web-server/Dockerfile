FROM chipster-web-server

COPY . /home/user/build

# /home/user/build/html overrides default files if it's added in the BuildConfig
RUN ls -lah /home/user/build || true \
    && ls -lah /home/user/build/html || true \
	&& mv /home/user/build/chipster-web/* /opt/chipster/web-root \
	&& mv /home/user/build/manual /opt/chipster/web-root/assets \
	&& cp -r /home/user/build/html /opt/chipster/web-root/assets || true \
	&& rm -rf /home/user/build/html || true \
	&& chmod ugo+rwx -R /opt/chipster/web-root \
	&& ls -lah /opt/chipster/web-root || true \
	&& ls -lah /opt/chipster/web-root/assets || true \
	&& ls -lah /opt/chipster/web-root/assets/manual | head || true \
	&& ls -lah /opt/chipster/web-root/assets/html || true

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
