FROM base-node

# copy the client code repo
COPY . /home/user/chipster-web/build

# remove the symlink becasue ng build doesn't tolerate it
# the source image already has the manual in place 
RUN cd /home/user/chipster-web/build \
	&& chmod ugo+rwx -R /home/user/chipster-web/build \
	&& npm ci \
	&& rm -rf src/assets/manual \
	&& npm run build -- --no-progress || true \
	&& cp -r dist/* ../ \
	&& cd .. \
	&& rm -rf build \
	&& ls -lah

CMD ["sleep", "inf"]
