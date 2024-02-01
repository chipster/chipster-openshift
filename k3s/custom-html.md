# Customize html pages
## Introduction

You can customize the front page and other html pages. It would be good to write at least 
what kind of usage is allowed on your server, who is maintaining it and how to contact you in case there
are any issues.

There are two ways to customize the html pages. In a single node setup you can simply mount a diretory from the host. In a cluster you have to find some other way to store your custom html files. Either way, the first thing is to clone a copy of the default files:

```bash
cd ~/git
git clone https://github.com/chipster/chipster-web.git
```

Here you can find the default files:

```bash
$ ls -lah chipster-web/src/assets/html
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

## Host mount

If your Chipster is running only on one node, the easiest way to customize the html pages is to mount them from the virtual machine host. 

After having a copy of the html files, add the following configuration to your `~/values.yaml` to mount those files from the host:

```yaml
html:
  hostPath: /home/ubuntu/git/chipster-web/src/assets/html
```

Deploy this change and wait until the pod has restarted:

```bash
bash deploy.bash -f ~/values.yaml
watch kubectl get pod
```

Now you can edit the files in `/home/ubuntu/git/chipster-web/src/assets/html`. Reload the web
browser to see your changes in the browser.

## Image build

If you plan to run Chipster in a multi-node cluster, you need some other way to store your custom html files. In a Kubernetes cluster, we can either store files in container images or on a volume. As the server isn't supposed to change these html pages and those are not huge in size, the container images are an obvious choice. 

These html files move from the code repository to the running container through two container images. The first image build, called [chipster-web](https://github.com/chipster/chipster-openshift/blob/kustomize-builds/kustomize/builds/chipster-web/Dockerfile) simply takes the code repository and builds the whole Angular application. The second image build, [web-server](https://github.com/chipster/chipster-openshift/blob/kustomize-builds/kustomize/builds/web-server/Dockerfile), collects files from multiple images: the app from the `chipster-web` image, the actual http server from the `chipster-web-server` image and manual pages from `chipster-tools` image. 

You could follow the [image build instructions](build-image.md) to fork the [chipster-web](https://github.com/chipster/chipster-web/tree/kustomize-builds) repository and build it. However, building the whole app takes almost 10 minutes and merging future changes to your forked repository might become a bit cumbersome. 

In the long run it's easier change the latter build `web-server`, which only combines files from other builds.

### First image build

Install Docker like shown in [image build instructions](build-image.md). After that you can continue from here.

After getting a copy of the html files, we'll build an image to use these files in Chipster. Before that you might want to make some change to `app-home.html` so that you can see if the files really changed in Chipster.

To build an image, we need a Dockerfile. Create a file ~/custom-html/Dockerfile and add the following content:

```
FROM base
COPY html /home/user/chipster-web/assets/html
RUN ls -lah /home/user
CMD ["sleep", "inf"]
```


Now we can build our `custom-html` image.

```
cd ~/git/chipster-openshift/k3s
sudo docker build -t custom-html -f ~/custom-html/Dockerfile ~/git/chipster-web/src/assets
```

Next we are going to build the web-server image by using these files as an input. Take a look at the default BuildConfig:

```
nano ../kustomize/builds/web-server/web-server.yaml 
```

Find a section like this (there are a few similar sections, but only the correct one has `destinationDir: html`):

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

Then we build and deploy the image again.

Build the image:

```bash
bash scripts/build-image.bash web-server
```

Copy the new image to K3s.

```bash
sudo docker save docker-registry.rahti.csc.fi/chipster-images-release/web-server | sudo k3s ctr -n k8s.io images import -
```

Restart the pod and wait until it starts:

```bash
kubectl rollout restart deployment/web-server
watch kubectl get pod
```

Reload the browser page and you should see your customizations in place.

### Next changes

Make your changes to the html files.
Build image, copy it and restart the pod:

```bash
sudo docker build -t custom-html -f ~/custom-html/Dockerfile ~/git/chipster-web/src/assets
bash scripts/build-image.bash web-server
sudo docker save docker-registry.rahti.csc.fi/chipster-images-release/web-server | sudo k3s ctr -n k8s.io images import -
kubectl rollout restart deployment/web-server
watch kubectl get pod
```

### After the public image has changed

```
bash pull-images.bash
bash scripts/build-image.bash web-server
sudo docker save docker-registry.rahti.csc.fi/chipster-images-release/web-server | sudo k3s ctr -n k8s.io images import -
kubectl rollout restart deployment/web-server
watch kubectl get pod
```