# Build images

## Introduction

Building container images will accomplish the following tasks:

* Checkout code repositories
* Compile code
* Install operating system packages

In effect we are executing commands defined in Dockerfiles. Most services will run with a minimal image with only Java and Chipster installed on top of Ubuntu, whereas some analysis tool containers require a huge number of operating system packages.


## Install Docker

We'll use Docker to build the images. Let's install it first.

```bash

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

## Two local image registries

There will be two local image registries involved in this process, one for K3s and one for Docker. The K3s image registry is used for running the containers and the Docker image registry is used for building the images. To use the new image, we have to copy it from the Docker registry to K3s registry. In this example we'll run the builds on the same Chipster host, but you could run the builds on different host if you don't want to install Docker on your production server.

Let's first check the images in K3s image registry:

```bash
$ sudo k3s crictl images
IMAGE                                                                 TAG                    IMAGE ID            SIZE
docker-registry.rahti.csc.fi/chipster-images/chipster-web-server-js   latest                 ba6b8e4832b16       280MB
docker-registry.rahti.csc.fi/chipster-images/chipster-web-server      latest                 d308fcb91521f       903MB
docker-registry.rahti.csc.fi/chipster-images/toolbox                  latest                 7f94300d1e138       904MB
docker-registry.rahti.csc.fi/chipster-images/web-server               latest                 e8c8edaaf2417       989MB
docker.io/bitnami/minideb                                             stretch                e398a222dbd61       22.2MB
docker.io/bitnami/postgresql                                          11.6.0-debian-9-r48    6db6971e4c89c       81.2MB
docker.io/rancher/klipper-helm                                        v0.7.3-build20220613   38b3b9ad736af       83MB
docker.io/rancher/klipper-lb                                          v0.3.5                 dbd43b6716a08       3.33MB
docker.io/rancher/local-path-provisioner                              v0.0.21                fb9b574e03c34       11.4MB
docker.io/rancher/mirrored-coredns-coredns                            1.9.1                  99376d8f35e0a       14.1MB
docker.io/rancher/mirrored-library-busybox                            1.34.1                 7a80323521ccd       777kB
docker.io/rancher/mirrored-library-traefik                            2.6.2                  72463d8000a35       30.3MB
docker.io/rancher/mirrored-metrics-server                             v0.5.2                 f73640fb50619       26MB
docker.io/rancher/mirrored-pause                                      3.6                    6270bb605e12e       301kB
```

At this point the Docker registry is still empty:

```bash
$ sudo docker images
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
```

## Building your own images

If you want to change something in these images, you can build your own image. The command is a bit different depending on whether the changes come from the GitHub or from the local directory. 

On a production server you probabaly want that all changes are recorded in the version control. In this 
case it makes sense to take the code directly from the version control repository.

On a development server you want to test changes as quickly as possible, so it makes sense to build the new image directly from the local directory. This allows you to try new things without making commits all the time.

### Option 1: Build from GitHub

For example, let's assume that you have forked [our chipster-tools](https://github.com/chipster/chipster-tools) repository to make your own changes to these scripts. 

Change the GitHub url in the buildconfig file to point to your repository. This same process would work also if you wanted to change the `Dockerfile` next to the buildconfig.

```bash
nano ../kustomize/builds/chipster-tools/chipster-tools.yaml
```

Now you can build the image that you changed and other images that are using it as their source. By looking at the `source` sections of the buildconfigs, you can see that this `chipster-tools` image is a source of two other images: `toolbox` and `web-server`. We should build those too.

```bash
bash scripts/build-image.bash chipster-tools
bash scripts/build-image.bash chipster-toolbox
bash scripts/build-image.bash web-server
```

### Option 2: Build from local directory

This example assumes that you want to make a change to the Java code in chipster-web-server repository.

Checkout the repository:

```bash
cd ~/git
git clone https://github.com/chipster/chipster-web-server.git
```

After you have done your changes to this directory, you can build the image. Check out the command that our build script would use:

```bash
cd ~/git/chipster-openshift/k3s
bash scripts/buildconfig-to-docker.bash ../kustomize/builds/chipster-web-server
```

It will print the docker build command:

```bash
cat ../kustomize/builds/chipster-web-server/Dockerfile | sudo docker build -t chipster-web-server -f - https://github.com/chipster/chipster-web-server.git
```

Run the command, but replace the repository URL in the end with a path to your local directory:

```bash
cat ../kustomize/builds/chipster-web-server/Dockerfile | sudo docker build -t chipster-web-server -f -  ~/git/chipster-web-server
```

## Copy image from Docker registry to K3s registry

Export the image (as a tar file) from Docker and import it to K3s.

```bash
sudo docker save IMAGE | sudo k3s ctr -n k8s.io images import -
```

For example, to copy the chipster-web-server image from Docker to K3s registry:

```bash
sudo docker save docker-registry.rahti.csc.fi/chipster-images/chipster-web-server | sudo k3s ctr -n k8s.io images import -
```

The K3s image registry requires us to use the long image names like `docker-registry.rahti.csc.fi/chipster-images/chipster-web-server`. It assumes that short names like `chipster-web-server` would refer to its default registry `docker.io/library/`.

You can also save the image to a file in between, if you wan't to use the same image on different Chipster server.

```bash
sudo docker save IMAGE -o image.tar
# after copied to another server
sudo k3s ctr -n k8s.io images import image.tar
```

## Start containers from the local image

The latest image in K3s image repository is now the locally build image. Simply restart a pod to take it in use. For example, to restart `toolbox`: 

```bash
kubectl rollout restart toolbox
```

## Build all images locally

There is a small helper script, in case you wan't to build all Chipster images yourself. It takes about half an hour. Remember to copy the built images to K3s registry like shown above.

```bash
bash scripts/build-image.bash --all
```
