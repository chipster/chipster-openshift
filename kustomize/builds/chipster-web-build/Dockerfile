FROM chipster-web

# remove the manual placeholder because the source image already has manual in place 
# npm ci --omit=dev does not install dev dependencies. gitlab-ci-audit.yml assumes this also
RUN cd /home/user \
	&& mv chipster-web chipster-web-build \
	&& cd chipster-web-build \
	&& chmod ugo+rwx -R /home/user/chipster-web-build \
	&& npm ci --omit=dev \
	&& rm -rf src/assets/manual \
	&& npm run build -- --no-progress || true \
	&& mkdir /home/user/chipster-web \
	&& cp -r dist/browser/* ../chipster-web \
	&& cd .. \
	&& rm -rf chipster-web-build \
	&& ls -lah

CMD ["sleep", "inf"]
