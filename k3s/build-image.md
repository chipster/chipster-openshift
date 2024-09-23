# Build images

## Introduction

Integration of new tool in Chipster often involves installation of new operating system packages, program binaries or other files. If the files are not huge (e.g. < 5 GB), it's advisable to build a new container image for it. The container image makes it explicit which dependendencies are needed to run the tool. Container images are not designed for huge files, so [a shared tools-bin directory](tools-bin-host-mount.md) still needs to be used for larger files.

This page shows you how to build an image to install dependencies for a tool. There are a few other examples at the end of the page in case you want to change some other images, for example the server code.

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

## Building your own images

Edit one of the current builds or add a new one:

```
nano ~/git/chipster-openshift/kustomize/builds/comp-r-4-2-3-enabrowsertools/Dockerfile
nano ~/git/chipster-openshift/kustomize/builds/comp-r-4-2-3-enabrowsertools/comp-r-4-2-3-enabrowsertools.yaml
```

Build it:

```
cd ~/git/chipster-openshift/k3s
bash scripts/build-image.bash comp-r-4-2-3-enabrowsertools
```

## Copy image from Docker registry to K3s registry

The command to export the image (as a tar file) from Docker and import it to K3s looks like this:

```bash
sudo docker save IMAGE | sudo k3s ctr -n k8s.io images import -
```

For example, to copy the comp-r-4-2-3-enabrowsertools image from Docker to K3s registry:

```bash
sudo docker save image-registry.apps.2.rahti.csc.fi/chipster-images/comp-r-4-2-3-enabrowsertools | sudo k3s ctr -n k8s.io images import -
```

The K3s image registry requires us to use the long image names like `image-registry.apps.2.rahti.csc.fi/chipster-images/comp-r-4-2-3-enabrowsertools`. It assumes that short names like `comp-r-4-2-3-enabrowsertools` would refer to its default registry `docker.io/library/`.

## Use the new image in a tool

Now we can modify the tool script header to use this image. Follow the [the tool script development instructions](tool-script-dev.md) to see how these scripts can be edited.

For example in the tool [enafetch.R](https://github.com/chipster/chipster-tools/blob/master/tools/common/R/enafetch.R):

First of all, define the name of the image. This will override the image definition in the runtime configuration:

```
# IMAGE comp-r-4-2-3-enabrowsertools
```

Set a [runtime](tool-script-dev.md#runtimes). The tool is written in R language, so Chipster needs to know how to find an R interpreter. In this case the source image [comp-r-4-2-4](https://github.com/chipster/chipster-openshift/tree/k3s/kustomize/builds/comp-r-4-2-3) already contains an R. We can also use an existing runtime `R-4.2.3` to tell Chipster that it can find the R in `/opt/chipster/tools/R-4.2.3/bin/R`.

```
# RUNTIME R-4.2.3
```

If we have managed to provide all the tool's dependendencies in the image, it shouldn't need the tools-bin directory anymore. Set it to an empty string `""` to tell Chipster that this tool doesn't need tools-bin at all.

```
# TOOLS_BIN ""
```

Note that these header lines have to be in this specific order (first TOOL, INPUT, OUTPUT, PAREMETER and then remaining lines in alphabetical order) for the header parser to find them.

Remember to [reload toolbox](tool-script-dev.md#reload-toolbox-after-tool-script-changes) to apply the changes.

## Appendix 1: Two local image registries

There are two local image registries involved in this process, one for K3s and one for Docker. The K3s image registry is used for running the containers and the Docker image registry is used for building the images. To use the new image, we have to copy it from the Docker registry to K3s registry. In the above example we ran the builds on the same Chipster host, but you could run the builds on different host if you don't want to install Docker on your production server.

Let's check the images in K3s image registry:

```bash
$ sudo k3s crictl images
IMAGE                                                                 TAG                    IMAGE ID            SIZE
image-registry.apps.2.rahti.csc.fi/chipster-images/chipster-web-server-js   latest                 ba6b8e4832b16       280MB
image-registry.apps.2.rahti.csc.fi/chipster-images/chipster-web-server      latest                 d308fcb91521f       903MB
image-registry.apps.2.rahti.csc.fi/chipster-images/toolbox                  latest                 7f94300d1e138       904MB
image-registry.apps.2.rahti.csc.fi/chipster-images/web-server               latest                 e8c8edaaf2417       989MB
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

The docker registry is still empty, if you haven't build any images yet:

```bash
$ sudo docker images
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
```

When copying image between these, you can also save the image to a file in between. This allows you to use the same image on different Chipster server.

```bash
sudo docker save IMAGE -o image.tar
# after copied to another server
sudo k3s ctr -n k8s.io images import image.tar
```

## Appendix 2: Build image for tool scripts

By default the Chipster uses tool scrips from a container image. [Tool script development instructions](tool-script-dev.md) show how to easily modify tool scripts on one or small number of servers. This example tries to mimic how the original Chipster image was build, in case you want to build your own set of container images, for example to put together your own special distribution of Chipster.

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

See [above](#appendix-1-two-local-image-registries) how to export the image to a file for you further use.

## Appnedix 3: Build server code from local repository

Most development of Chipster platform itself is done by running the Java code directly on a laptop without any containers (TODO write instructions for setting this up). Some features or bugs can be tested only in containers. This example shows how to build a container image from you custom server code.

When developing the server code you want to test changes as quickly as possible, so it makes sense to build the new image directly from the local directory. This allows you to try new things without making commits all the time.

Building a container image will accomplish the following tasks:

- Checkout code repositories
- Compile code
- Install operating system packages

In effect we are executing commands defined in Dockerfiles. Most services will run with a minimal image with only Java and Chipster installed on top of Ubuntu, whereas some analysis tool containers require a huge number of operating system packages.

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

The latest image in K3s image repository is now the locally build image. Simply restart a pod to take it in use. For example, to restart the API server `session-db`:

```bash
kubectl rollout restart session-db
```
