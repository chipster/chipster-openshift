# Customize html pages

[You can customize the front page][custom-html.md] and other html pages. It would be good to write at least 
what kind of usage is allowed on your server, who is maintaining it and how to contact you in case there
are any issues.

First of all, we need to decide where to store the our custom pages. In a Kubernetes cluster, we can either store files in container images or on a volume. As the server isn't supposed to change these html pages and those are not huge in size, the container images are an obvious choice. 

These html files move from the code repository to the running container through two container images. The first image build, called [chipster-web][https://github.com/chipster/chipster-openshift/blob/kustomize-builds/kustomize/builds/chipster-web/Dockerfile] simply takes the code repository and builds the whole Angular application. The second image build, [web-server][https://github.com/chipster/chipster-openshift/blob/kustomize-builds/kustomize/builds/chipster-web/Dockerfile], collects file from many images: the app from the `chipster-web` image, the actual http server from the `chipster-web-server` image and manual pages from `chipster-tools` image. 

You could follow the [image build instructions][build-image.md] to fork the [chipster-web][https://github.com/chipster/chipster-web/tree/kustomize-builds] and build it. However, building the whole app takes almost 10 minutes and merging future changes to your forked repository might become a bit cumbersome. 

In the long run it's easier change the latter build `web-server`, which only combines files from other builds.

Let's clone a copy of the default files.

```
cd ~/git
git clone https://github.com/chipster/chipster-web.git
cd chipster-web
git checkout k3s
```

Here you can find the default files:

```
$ ls -lah src/assets/html
total 92K
drwxrwxr-x 2 ubuntu ubuntu 4.0K Apr  1 06:24 .
drwxrwxr-x 6 ubuntu ubuntu 4.0K Apr  1 06:24 ..
-rw-rw-r-- 1 ubuntu ubuntu 1002 Apr  1 06:24 access.html
-rw-rw-r-- 1 ubuntu ubuntu  812 Apr  1 06:24 accessibility.html
-rw-rw-r-- 1 ubuntu ubuntu  230 Apr  1 06:24 app-chipster-icon.png
-rw-rw-r-- 1 ubuntu ubuntu 2.3K Apr  1 06:24 app-contact.html
-rw-rw-r-- 1 ubuntu ubuntu  428 Apr  1 06:24 app-home-header.html
-rw-rw-r-- 1 ubuntu ubuntu  712 Apr  1 06:24 app-home.html
-rw-rw-r-- 1 ubuntu ubuntu  54K Apr  1 06:24 app-web-header-image.png
-rw-rw-r-- 1 ubuntu ubuntu  113 Apr  1 06:24 terms-of-use-v1.html
```

Next we'll try to build an image to use these files in Chipster. Before that you might want to make some change to `app-home.html` so that you can see if the files really changed in Chipster.

To build an image, we need a Dockerfile. Create a file ~/custom-html/Dockerfile and add the following content:

```
FROM base
COPY html /home/user/chipster-web/assets/html
RUN ls -lah /home/user
CMD ["sleep", "inf"]
```

The build will use an image called `base` as a base image. Let's pull it from a public image repository:

```
sudo docker pull docker-registry.rahti.csc.fi/chipster-images/base
```

Then we can build our image.

```
sudo docker build -t custom-html -f ~/custom-html/Dockerfile ~/git/chipster-web/src/assets
```

Next we are going to build the web-server image by using these files as an input.

```
cd ~/git/chipster-openshift/k3s
```

Let's take a look how the image is build normally:

```
$ bash scripts/buildconfig-to-docker.bash ../kustomize/builds/web-server
cat ../kustomize/builds/web-server/Dockerfile | sed "s#COPY chipster-web /opt/chipster#COPY --from=chipster-web:latest /home/user/chipster-web /opt/chipster/chipster-web#" | sed "s#COPY html /opt/chipster/chipster-web/assets#COPY --from=chipster-web:latest /home/user/chipster-web/assets/html /opt/chipster/chipster-web/assets/html#" | sed "s#COPY manual /opt/chipster/chipster-web/assets#COPY --from=chipster-tools:latest /home/user/chipster-tools/manual /opt/chipster/chipster-web/assets/manual#" | sudo docker build -t web-server -
```

So the command takes our Dockerfile (written for another container platform called OpensShift) and adjusts the COPY commands to work in Docker. Remove the last command to see the end results:

```bash
$ cat ../kustomize/builds/web-server/Dockerfile | sed "s#COPY chipster-web /opt/chipster#COPY --from=chipster-web:latest /home/user/chipster-web /opt/chipster/chipster-web#" | sed "s#COPY html /opt/chipster/chipster-web/assets#COPY --from=chipster-web:latest /home/user/chipster-web/assets/html /opt/chipster/chipster-web/assets/html#" | sed "s#COPY manual /opt/chipster/chipster-web/assets#COPY --from=chipster-tools:latest /home/user/chipster-tools/manual /opt/chipster/chipster-web/assets/manual#"
FROM chipster-web-server

COPY --from=chipster-web:latest /home/user/chipster-web /opt/chipster/chipster-web
# copy html separately so that the BuildConfig can be patched to take it from another image
COPY --from=chipster-web:latest /home/user/chipster-web/assets/html /opt/chipster/chipster-web/assets/html
COPY --from=chipster-tools:latest /home/user/chipster-tools/manual /opt/chipster/chipster-web/assets/manual

RUN mv /opt/chipster/chipster-web /opt/chipster/web-root \	
	&& chmod ugo+rwx -R /opt/chipster/web-root \
	&& ls -lah /opt/chipster/web-root || true \
	&& ls -lah /opt/chipster/web-root/assets || true \
	&& ls -lah /opt/chipster/web-root/assets/manual | head || true \
	&& ls -lah /opt/chipster/web-root/assets/html || true

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
```

The build requires a few other images. Let's pull them:

```
sudo docker pull docker-registry.rahti.csc.fi/chipster-images/chipster-web-server
sudo docker pull docker-registry.rahti.csc.fi/chipster-images/chipster-web
sudo docker pull docker-registry.rahti.csc.fi/chipster-images/chipster-tools
```

Also, you can see that `html` directory is now taken from an `chipster-web` image, but we wan't to take it from our new image `custom-html` instead. Let's modify the command a bit and change that image:

```
$ cat ../kustomize/builds/web-server/Dockerfile | sed "s#COPY chipster-web /opt/chipster#COPY --from=chipster-web:latest /home/user/chipster-web /opt/chipster/chipster-web#" | sed "s#COPY html /opt/chipster/chipster-web/assets#COPY --from=custom-html:latest /home/user/chipster-web/assets/html /opt/chipster/chipster-web/assets/html#" | sed "s#COPY manual /opt/chipster/chipster-web/assets#COPY --from=chipster-tools:latest /home/user/chipster-tools/manual /opt/chipster/chipster-web/assets/manual#"
FROM chipster-web-server

COPY --from=chipster-web:latest /home/user/chipster-web /opt/chipster/chipster-web
# copy html separately so that the BuildConfig can be patched to take it from another image
COPY --from=custom-html:latest /home/user/chipster-web/assets/html /opt/chipster/chipster-web/assets/html
COPY --from=chipster-tools:latest /home/user/chipster-tools/manual /opt/chipster/chipster-web/assets/manual

RUN mv /opt/chipster/chipster-web /opt/chipster/web-root \	
	&& chmod ugo+rwx -R /opt/chipster/web-root \
	&& ls -lah /opt/chipster/web-root || true \
	&& ls -lah /opt/chipster/web-root/assets || true \
	&& ls -lah /opt/chipster/web-root/assets/manual | head || true \
	&& ls -lah /opt/chipster/web-root/assets/html || true

CMD ["java", "-cp", "lib/*:", "fi.csc.chipster.web.WebServer"]
```

That looks good. Let's build it by putting back the `| sudo docker build -t web-server -` to the end and running it.

```
cat ../kustomize/builds/web-server/Dockerfile | sed "s#COPY chipster-web /opt/chipster#COPY --from=chipster-web:latest /home/user/chipster-web /opt/chipster/chipster-web#" | sed "s#COPY html /opt/chipster/chipster-web/assets#COPY --from=custom-html:latest /home/user/chipster-web/assets/html /opt/chipster/chipster-web/assets/html#" | sed "s#COPY manual /opt/chipster/chipster-web/assets#COPY --from=chipster-tools:latest /home/user/chipster-tools/manual /opt/chipster/chipster-web/assets/manual#" | sudo docker build -t web-server -
```

Then we have to configure the Chipster to use this local image. Add the following to your ~/values.yaml file:

```
deployments:
  webServer:
    useDefaultImageRepo: false
```

Deploy it.

```
bash deploy.bash -f ~/values.yaml
```

Restart the pod and wait until it starts:

```
kubectl rollout restart deployment/web-server
watch kubectl get pod
```

Reload the browser page and you should see your customizations in place.
