# Chipster in k3s

## Overview

These instructions show how to install the Chipster web app v4 to an Ubuntu server. 

Chipster is based on microservice architecture. There is about a dozen different services, but each of service tries to be relatively simple and independent. Each service is run in its own container. The containers are orchestrated with Lightweight Kubernetes k3s.

The user interface in the v4 is a single-page-application (SPA) running in the user's browser. Commnad line client and Rest APIs are also available.

## Status

Chipster v4 is under heavy development and is still a bit rough around the edges. Nevertheless, it should be nicely usable for the end users running real analysis jobs. We are running it ourselves for that purpose. Many architectural choices are based on the old tried-and-tested Chipster v3.

However, tha same cannot be said about these installation instructions. These are the first attempt to show how to get the Chipster running. 

To get started as fast as possible, these instructinos assume that were are setting up a new single-node server. At this point we don't promise to offer complete instructions for updating this server to new Chipster versions later. Especially migrating the user's sessions and files from one version to another is not always trivial. We do try to provide the critical pointers, because we are migrating our own installations anyway. 

The same goes for many other aspcects of configuring and maintaining the server. Many empty titles are added to highlight different aspects that you should considered when running a server in the public internet. Luckily many of these topics are not actually specific to Chipster (e.g. how to setup https or worker nodes for k3s). Pull requests for improving this documenation are very much welcome.

These instructions aim to build everything starting from the plain files in GitHub. It's little bit more work, but it allows you update the installation to which ever GitHub branch or fork of Chipster. It also makes it easy to change any part of the system easily. This will be useful now in these early phases of the project. Maybe later we could provide compiled code packges, container images and Helm Charts in public repositories making the initial installation easier, but raising the bar for custom modifications.

## Why k3s

K3s is a Light Kubernetes, effectively a container cloud platform. Do we really need the cointainer cloud platform to run a few server processes on single host? Not really, you could checkout the code yourself and follow the Dockerfiles to see what kind of folder structure is needed for each service, how to compile the code and how to start the processes. Add some form of reverse proxy to terminate HTTPS (e.g. Apache or nginx) and some process monitoring (Java Service Wrapper or systemd) and you are done.

K3s offers standardized way of doing all that. In allows us to run small-scale Chipster in very similar environment, that we know well from our larger production installations.

## Installation
### Requirements
#### Firewall

Let's assume that we have a ssh access to an Ubuntu 16.04 server. It doesn't matter if it is a physical hardwware or a virtual server.

Make sure that you have firewall a (in the network / IaaS cloud or the Ubuntu's local iptables) that allows only 
* inbound access from your laptop to ports 22 (ssh), 80 (http) and maybe also 443 for https in the future
* outbound access to anything

Especially make sure to protect the port X that k3s would use for cummunicating with other k3s nodes.

#### Hardware Resources

### Install k3s

```bash
curl -sfL https://get.k3s.io | sh -
# Check for Ready node
sudo k3s kubectl get node
```

Copied from [https://k3s.io](https://k3s.io).

### Install Docker

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
sudo systemctl status docker
```

See [https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04) for more detailed instructions.

### Install yq

```bash
sudo add-apt-repository ppa:rmescandon/yq
sudo apt update
sudo apt install yq -y
```

### Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# configure Helm to use k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo bash -c "kubectl config view --raw >~/.kube/config"
```

More installation options are available in [https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/).

### Build Images

Building container images will accomplish the following tasks
* Checkout code repositories
* Compile code
* Install operating system packages

In effect we are executing commands defined in Dockerfiles. Most services will run with a minimal image with only Java and Chipster installed on top of Ubuntu, whereas the comp (i.e. analysis) service requires a huge number of operating system
packages.

Checkout deployment scripts.

```bash
cd
mkdir git
cd git
git clone https://github.com/chipster/chipster-openshift
cd chipster-openshift
```

Build images. The information about build dependencies is in the BuildConfig objects (supported in OpenShfit, another variant of Kubernetes), which don't work in k3s. We have to dig out the GitHub urls and some paths from these objects in bash.

```bash
set -e

# these build need only a Dockerfile
for build in base base-java base-node comp-base; do
    sudo docker build -t $build templates/builds/$build
done

# these builds need a Dockerfile and GitHub repo
for build in chipster-tools chipster-web chipster-web-server chipster-web-server-js; do
    uri=$(cat templates/builds/$build/$build.yaml | yq r - objects[0].spec.source.git.uri)

    cat templates/builds/$build/Dockerfile | sudo docker build -t $build -f - $uri
done

# these builds need a Dockerfile and a folder from other image
for build in toolbox; do
    image=$(cat templates/builds/$build/$build.yaml | yq r - objects[0].spec.source.images[0].from.name)
    destination=$(cat templates/builds/$build/$build.yaml | yq r - objects[0].spec.source.images[0].paths[0].destinationDir)
    source=$(cat templates/builds/$build/$build.yaml | yq r - objects[0].spec.source.images[0].paths[0].sourcePath)

    cat templates/builds/$build/Dockerfile | sed "s#COPY tools#COPY --from=$image $source#" | tee /dev/tty | sudo docker build -t $build -
done
```

List images.

```bash
sudo docker images
```

Which should show you something like this:

```bash
REPOSITORY               TAG                 IMAGE ID            CREATED             SIZE
chipster-web-server-js   latest              a61b26ae2a65        47 seconds ago      777MB
chipster-web-server      latest              15a75511dbe0        4 minutes ago       1.52GB
chipster-web             latest              3e734da8cd32        5 minutes ago       715MB
comp-base                latest              f3bec98fd5e1        12 minutes ago      1.97GB
base-node                latest              101b5ec7c6c6        16 minutes ago      568MB
toolbox                  latest              fc647ad26a7c        23 minutes ago      1.53GB
chipster-tools           latest              42f2234dcc0c        23 minutes ago      307MB
base-java                latest              f2b909db4288        3 hours ago         1.21GB
base                     latest              e4af660abe0f        3 hours ago         259MB
ubuntu                   16.04               56bab49eef2e        2 weeks ago         123MB
```

### Import images

Export the images from Docker and import to k3s.

```bash
for path in $(ls templates/builds/); do
    image=$(basename $path)
    echo $image
    sudo docker save $image | sudo k3s ctr images import -
done
```

### Update images

TODO How to rebuild the images after something has changed?

### Deploy

sudo helm install chipster --generate-name --set ingress.enabled=true --set ingress.hosts[0].paths[0]="/nginx" --set ingress.annotations."traefik\.frontend\.rule\.type"=PathPrefixStrip

## Configuration and Maintenance

### Chipster settings

TODO How to change Chispter configuration files

### Persistent storage

### Download tools-bin

### Wildcard DNS

TODO Now we have each service running in different port, i.e. web-server in chipster-host.com:8000 and 
session-db in chipster-host.com:8004. How to configure k3s and a wildcard DNS record, so that we could use web-server.chipster-host.com and session-db.chipster-host.com with default ports?

### HTTPS

TODO With Let's Encrypt certificates?

### Authentication
#### OpenID Connect

TODO Works e.g. with Google authentication, but then all Google accounts have full user permissions in Chipster. Access can be restricted with firewalls or by using other more exclusive OpenID Connect providers.

#### LDAP authentication

TODO A similar jaas config should still work like in the old Chipster v3, but it hasn't been tested.

#### File authentication

TODO A file in security/users, just like in the old Chipster v3.

### Backups
#### Backup deployment configuration

TODO

#### Backup databases

TODO FileBroker can encrypt and upload incremental file backups to S3. BackupArchive can download those from S3 to a local disk on some other server.

#### Backup files

TODO fi.csc.chispter.backup.Backup can take db dumps, encrypt and upload those to S3. BackupArchive can download those from S3 to a local disk on some other server.

### Logging

TODO Collect logs with Filebeat and push them to Logstash

### Graphana

TODO Collect statistics from the admin Rest API, push them to InfluxDB and show in Grafana

### Monitoring and session replay tests

TODO Configure ReplayServer

### Customize front page, contact details and terms of use

TODO in app-*.html files in chipster-tools image in /home/user/chipster-tools/manual (?)



