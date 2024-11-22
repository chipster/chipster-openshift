FROM chipster-web

# remove the manual placeholder because the source image already has manual in place 
RUN cd /home/user \
	&& mv chipster-web chipster-web-build \
	&& cd chipster-web-build \
	&& chmod ugo+rwx -R /home/user/chipster-web-build \
	&& npm ci \
	&& rm -rf src/assets/manual \
	&& npm run build -- --no-progress || true \
	&& mkdir /home/user/chipster-web \
	&& cp -r dist/browser/* ../chipster-web \
	&& cd .. \
	&& rm -rf chipster-web-build \
	&& ls -lah

CMD ["sleep", "inf"]
