# Customize html pages
## Introduction

[You can customize the front page][custom-html.md] and other html pages. It would be good to write at least 
what kind of usage is allowed on your server, who is maintaining it and how to contact you in case there
are any issues.

First of all, we need to decide where to store the our custom pages. In a Kubernetes cluster, we can either store files in container images or on a volume. As the server isn't supposed to change these html pages and those are not huge in size, the container images are an obvious choice. 

These html files move from the code repository to the running container through two container images. The first image build, called [chipster-web][https://github.com/chipster/chipster-openshift/blob/kustomize-builds/kustomize/builds/chipster-web/Dockerfile] simply takes the code repository and builds the whole Angular application. The second image build, [web-server][https://github.com/chipster/chipster-openshift/blob/kustomize-builds/kustomize/builds/chipster-web/Dockerfile], collects file from many images: the app from the `chipster-web` image, the actual http server from the `chipster-web-server` image and manual pages from `chipster-tools` image. 

You could follow the [image build instructions][build-image.md] to fork the [chipster-web][https://github.com/chipster/chipster-web/tree/kustomize-builds] and build it. However, building the whole app takes almost 10 minutes and merging future changes to your forked repository might become a bit cumbersome. 

In the long run it's easier change the latter build `web-server`, which only combines files from other builds.

## First time

Let's clone a copy of the default files.

```
cd ~/git
git clone https://github.com/chipster/chipster-web.git
cd chipster-web
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

The build will use an image called `base` as a base image. Let's pull all Chipster images from a public image repository:

```
cd ~/git/chipster-openshift/k3s
bash pull-images.bash
```

Then we can build our `custom-html` image.

```
sudo docker build -t custom-html -f ~/custom-html/Dockerfile ~/git/chipster-web/src/assets
```

Next we are going to build the web-server image by using these files as an input. Take a look at the default BuildConfig:

```
nano ../kustomize/builds/web-server/web-server.yaml 
```

Find a section like this (there are a few similar sections, but only the corret one has `destinationDir: html`):

```yaml
    - as: null
      from:
        kind: ImageStreamTag
        name: chipster-web:latest
      paths:
      - destinationDir: html
        sourcePath: /home/user/chipster-web/assets/html
```

Change the `chipster-web` to your own image `custom-html`. Press Ctrl+O, Enter, Ctrl+X to save and close the editor.

Then we simply build and deploy the image again. I'll simply list the commands here. Please see the [image build instructions][build-image.md] for longer explanations.

Build the image:

```
bash scripts/build-image.bash web-server
```

Configure the Chipster to use this local image. Add the following to your ~/values.yaml file:

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

## Next changes

Make your changes to the html files.
Build images and restart the pod:

```
sudo docker build -t custom-html -f ~/custom-html/Dockerfile ~/git/chipster-web/src/assets
bash scripts/build-image.bash web-server
kubectl rollout restart deployment/web-server
watch kubectl get pod
```

## After the public image has changed

```
bash pull-images.bash
bash scripts/build-image.bash web-server
kubectl rollout restart deployment/web-server
watch kubectl get pod
```