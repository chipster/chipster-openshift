# Build images

Building container images will accomplish the following tasks:

* Checkout code repositories
* Compile code
* Install operating system packages

In effect we are executing commands defined in Dockerfiles. Most services will run with a minimal image with only Java and Chipster installed on top of Ubuntu, whereas the comp (i.e. analysis) service requires a huge number of operating system
packages.

Let's check our current images:

```bash
$ sudo docker images
REPOSITORY                                                             TAG                   IMAGE ID            CREATED             SIZE
docker-registry.rahti.csc.fi/chipster-jenkins/web-server               latest                cacf01c1a492        23 minutes ago      1.72GB
docker-registry.rahti.csc.fi/chipster-jenkins/toolbox                  latest                3339746c88c1        28 minutes ago      1.57GB
docker-registry.rahti.csc.fi/chipster-images/chipster-web-server       latest                cb9257dac46e        32 minutes ago      1.5GB
docker-registry.rahti.csc.fi/chipster-images/chipster-web-server-js    latest                2a73dd624962        34 minutes ago      766MB
docker-registry.rahti.csc.fi/chipster-jenkins/comp                     latest                471fecae8202        2 weeks ago         2.11GB
docker-registry.rahti.csc.fi/chipster-jenkins/chipster-web-server-js   latest                fb7d0c3fb87f        2 weeks ago         819MB
docker-registry.rahti.csc.fi/chipster-jenkins/web-server               <none>                e8e4fdca93d5        2 weeks ago         1.72GB
docker-registry.rahti.csc.fi/chipster-jenkins/toolbox                  <none>                3c992e1de945        2 weeks ago         1.57GB
docker-registry.rahti.csc.fi/chipster-jenkins/chipster-web-server      latest                9c88753a944c        2 weeks ago         1.56GB
docker-registry.rahti.csc.fi/chipster-jenkins/base                     latest                98a49405eabc        2 weeks ago         298MB
bitnami/minideb                                                        stretch               ed288f60eff7        3 weeks ago         53.7MB
bitnami/postgresql                                                     11.6.0-debian-9-r48   6db6971e4c89        7 weeks ago         225MB
busybox                                                                latest                6d5fcfe5ff17        2 months ago        1.22MB
traefik                                                                1.7.19                aa764f7db305        4 months ago        85.7MB
rancher/metrics-server                                                 v0.3.6                9dd718864ce6        4 months ago        39.9MB
rancher/local-path-provisioner                                         v0.0.11               9d12f9848b99        5 months ago        36.2MB
coredns/coredns                                                        1.6.3                 c4d3d16fe508        6 months ago        44.3MB
nginx                                                                  1.16.0                ae893c58d83f        6 months ago        109MB
rancher/klipper-lb                                                     v0.1.2                897ce3c5fc8f        9 months ago        6.1MB
rancher/pause                                                          3.1                   da86e6ba6ca1        2 years ago         742kB
```

If you want to change something in these images, you can build your own image. For example, let's assume that you have forked [our chipster-tools](https://github.com/chipster/chipster-tools) repository to make your own changes to these scripts. 

Change the GitHub url in the buildconfig file to point to your repository. This same process would work also if you wanted to change the `Dockerfile` next to the buildconfig.

```bash
nano ../templates/builds/chipster-tools/chipster-tools.yaml
```

The current build script assumes that all source image are present locally. You can either 
pull the images from a public image repository:

```
bash pull-images.bash
```

Or you can build all images once which takes about half an hour:

```bash
bash scripts/build-image.bash --all
```

Now that Docker has local copies of the source images, you can build only the image that you changed and other images that are using it as their source. By looking at the `source` sections of the buildconfigs, you can see that this `chipster-tools` image is a source of two other images: `toolbox` and `web-server`. We have to build those too.

```bash
bash scripts/build-image.bash chipster-tools
bash scripts/build-image.bash chipster-toolbox
bash scripts/build-image.bash web-server
```

Then we have to change our deployment to use these new images. In practice we only have to disable use of the default image repository for those Chipster services in our `~/values.yaml`. After this the deployment will use your own local image.

```yaml
deployments:
  toolbox:
    useDefaultImageRepo: false
  webServer:
    useDefaultImageRepo: false
```

Finally, deploy changes.

```bash
bash deploy.bash -f ~/values.yaml
``` 
