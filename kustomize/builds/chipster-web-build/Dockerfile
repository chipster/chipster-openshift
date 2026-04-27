FROM chipster-web

# remove the manual placeholder because the source image already has manual in place 
# npmn ci installs also dev dependencies, because ng build needs them. ng build is run with a prod configuration, which gets rid of extra dependencies from the dist version
# Use --ignore-scripts for safety (and we don't need them).
RUN cd /home/user \
	&& mv chipster-web chipster-web-build \
	&& cd chipster-web-build \
	&& chmod ugo+rwx -R /home/user/chipster-web-build \
	&& npm ci --ignore-scripts \
	&& rm -rf src/assets/manual \
	&& npm run build -- --no-progress || true \
	&& mkdir /home/user/chipster-web \
	&& cp -r dist/browser/* ../chipster-web \
	&& cd .. \
	&& rm -rf chipster-web-build \
	&& ls -lah

CMD ["sleep", "inf"]
