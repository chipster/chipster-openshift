FROM base-node

# copy the client code repo
COPY . /home/user/chipster-web/build

# remove the manual placeholder because the source image already has manual in place 
RUN cd /home/user/chipster-web/build \
	&& chmod ugo+rwx -R /home/user/chipster-web/build \
	&& npm ci \
	&& rm -rf src/assets/manual \
	&& npm run build -- --no-progress || true \
	&& cp -r dist/browser/* ../ \
	&& cd .. \
	&& rm -rf build \
	&& ls -lah

CMD ["sleep", "inf"]
