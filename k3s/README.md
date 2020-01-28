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

K3s is a Lightweight Kubernetes, effectively a container cloud platform. Do we really need the cointainer cloud platform to run a few server processes on single host? Not really, you could checkout the code yourself and follow the Dockerfiles to see what operating system packages and what kind of folder structure is needed for each service, how to compile the code and how to start the processes. Add some form of reverse proxy to terminate HTTPS (e.g. Apache or nginx) and some process monitoring (Java Service Wrapper or systemd) and you are done.

However, k3s offers standardized way of doing all that and we don't want to implement ourselves functionalities that are already offered  by the container cloud platforms, like HTTPS termination. K3s allows us to run small-scale Chipster in very similar environment, that we know well from our larger production installations. We aim to rely even more on the Kubernetes features in the future. For example, it would be nice to run each Chipster job in its own container. This would make it easier to manage tool dependencies and improve security. 

## Installation
### Requirements
#### Access

Let's assume that we have a ssh access to an Ubuntu 16.04 server. It doesn't matter if it is a physical hardwware or a virtual server.

We need a lot of storage space to store all the reference genomes, indexes and databases. 
 * mount at least 1 TB volume to the server
 * create a filesystem to the volume 
 ```bash
 sudo mkfs.xfs -f -L data /dev/vdb
 ```
 * configure the volume mount
 ```bash
sudo bash -c "echo 'LABEL=data	/mnt/data	xfs	defaults	0	0' >> /etc/fstab"
 ```
 * mount it
 ```bash
sudo mount -a
 ```
 * make sure you can see it
 ```bash
 $ df -h
 ---
 /dev/vdb            1000G   60G  940G   6% /mnt/data
 ---
 ```
 * create a symlink to use the volume for k3s volume storage
 ```bash
 sudo mkdir -p /mnt/data/k3s/storage /var/lib/rancher/k3s/
 ln -s /mnt/data/k3s/storage /var/lib/rancher/k3s/storage
 ```

 * create a symlink to use the volume for container root and emptyDir volumes. We'll need a large emptyDir volume for temporary directory of the tools-bin download. K3s stores both root and emptyDir volumes in the same place.

 ```bash
sudo mkdir -p /mnt/data/k3s/pods /var/lib/kubelet
ln -s /mnt/data/k3s/pods /var/lib/kubelet/pods
 ```

The instructions assume that your account has passwordless sudo rights. TODO how to set it up?

#### Firewall

Make sure that you have firewall a (in the network / IaaS cloud or the Ubuntu's local iptables) that allows only 
* inbound access from your laptop to ports 22 (ssh), 80 (http) and maybe also 443 for https in the future
* inbound access from this machine itself (ports 80 and 443). In OpenStack Security groups this would mean from the IP address of the tenant's router. TODO make it start without this
* outbound access to anything

Especially make sure to protect the port X that k3s would use for cummunicating with other k3s nodes (although we are going to install only one node now).

#### Hardware Resources

TODO

### Install Docker

We'll use Docker to to build container images.

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
sudo systemctl status docker
```

See [https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04) for more detailed instructions.

### Install k3s

```bash
curl -sfL https://get.k3s.io | sh -
# Check for Ready node
sudo k3s kubectl get node
```

Allow the current user to use `kubectl` command with k3s without `sudo`.

```bash
sudo bash -c "kubectl config view --raw " > ~/.kube/config
echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc; source ~/.bashrc
```

We'll use Docker to build container images. Let's configure K3s to also run images with Docker so the images are readily available in Docker after each build. By default K3s would run containers with Containerd, and we would have to copy each image from Docker to Containerd (`sudo docker save $image | sudo k3s ctr images import -`).

```bash
sudo sed -i 's/server \\/server --docker \\/' /etc/systemd/system/k3s.service
sudo systemctl restart k3s
```

### Install other utils

`yq` for parsing yaml files.

```bash
sudo add-apt-repository ppa:rmescandon/yq
sudo apt update
sudo apt install yq -y
```

`jq` for parsing json.

```bash
sudo apt install jq -y
```

### Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

More installation options are available in [https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/).

### Check that k3s and Helm work

TODO deploy nginx to test that k3s and helm work.

```bash
helm create ...
helm install nginx-test --generate-name --set ingress.enabled=true --set ingress.hosts[0].paths[0]="/nginx" --set ingress.annotations."traefik\.frontend\.rule\.type"=PathPrefixStrip
```

TODO check that you can see the nginx welcome page in your browser before starting to deploy Chipster.

TODO remove nginx-test

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

Let's build the images. The information about build dependencies is in the BuildConfig objects (supported in OpenShfit, another variant of Kubernetes), which don't work in k3s. We have to dig out the GitHub urls and some paths from these objects in bash. There is a small utility scripts that converts the BuildConfig and Dockerfile to a `docker build` command. For example running

```bash
bash k3s/buildconfig-to-docker.bash templates/builds/base
```
prints
```bash
cat ../templates/builds/base/Dockerfile | tee /dev/tty | sudo docker build -t base -
```

This one was simple, but it gets a bit tortuous when the images copy directories from other images:

```bash
$ bash k3s/buildconfig-to-docker.bash templates/builds/web-server
```

```bash
cat templates/builds/web-server/Dockerfile | sed "s#COPY chipster-web /opt/chipster#COPY --from=chipster-web:latest /home/user/chipster-web /opt/chipster/chipster-web#" | sed "s#COPY manual /opt/chipster/chipster-web/assets#COPY --from=chipster-tools:latest /home/user/chipster-tools/manual /opt/chipster/chipster-web/assets/manual#" | tee /dev/tty | sudo docker build -t web-server -
```

You could repeat that command to build an image from each diretory in `templates/builds`, or we can use a bash loop to do that for us:

```bash
set -e

for build in $(ls templates/builds/ | grep -v chipster-jenkins | grep -v web-server-mylly); do
    echo "** $build"
    cmd="$(bash k3s/buildconfig-to-docker.bash templates/builds/$build)"
    echo "build command: $cmd"
    bash -c "$cmd"
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

### Update images

TODO How to rebuild the images after something has changed?

Restart all pods:

```bash
bash restart.bash
```

### Deploy

First we generate passwords. 

Helm doesn't seem to have a standard way for handling passwords. Our solution is to have a separate bash script which generates the passwords and stores them in a Kubernetes `secret`. The passwords are stored in a same format as the `values.yaml` in the Chipster Helm chart.

```bash
bash generate-passwords.bash
```

Then we deloy the Chipster itself. Replace `HOST_ADDRESS` with host machine's public IP address or DNS name.

The script takes the passwords from the `passwords` secret that we just created.

```bash
bash deploy.bash --set host=HOST_ADDRESS --set toolsBin.version=chipster-3.15.6
```

See when pod's are running (hit Ctlr + C to quit).

```bash
watch kubectl get pod
```

## Configuration and Maintenance

### Getting started with k3s

Please see [Getting started with k3s](getting-started-with-k3s.md) for k3s basics.

### Chipster settings

TODO How to change Chispter configuration files

### Admin view

 * check the password of `admin` user account from the auth

 ```bash
 kubectl exec deployment/auth -it -- cat security/users
 ```

 * when logged in with that account, there is `Admin` link in the nav bar. Click that link to see the Admin view

### Persistent storage

Postgres databases are defined as a dependency of the chipster Helm chart. When you deploy the chipster Helm chart, also the databases are deployed.

FIXME this must be run before the chipster is deployed

```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm dependency update helm/chipster
```

If you deploy the databases repeatedly to try different settings, note that `helm uninstall auth` won't delete the `pvc`, which has to be deleted separately (`kubectl delete pvc data-auth-postgresql-0`). Otherwise e.g. the database password won't change.

```
NAME: session-db
LAST DEPLOYED: Tue Jan  7 14:43:59 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 5432 on the following DNS name from within your cluster:

    session-db-postgresql.default.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace default session-db-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)

To connect to your database run the following command:

    kubectl run session-db-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.6.0-debian-9-r0 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host session-db-postgresql -U postgres -d postgres -p 5432

```

### Download tools-bin

Run the deployment with a parameter `--set toolsBin.version=chipster-3.15.6` to start a job which downloads the tools-bin package. 

Use the following command to follow its logs. Please note that dots in the version number are replaced with dashes in the job name because of Kubernetes' name requirements.

```bash
kubectl logs job/download-tools-bin-chipster-3-15-6 -f
```

When the download is completed, you should restart all pods, e.g.

```bash
bash restart.bash
```

If the download doesn't start, use the following commands to check the name and status of the `job`, `pod`, `pvc` and `pv` objects and then use `kubectl describe OBJECT_TYPE OBJECT_NAME` to see more details about those.

```bash
kubectl get job
kubectl get pod
kubectl get pvc
kubectl get pv
```

### Wildcard DNS

TODO Now we have each service running in different port, i.e. web-server in chipster-host.com:8000 and 
session-db in chipster-host.com:8004. How to configure k3s and a wildcard DNS record, so that we could use web-server.chipster-host.com and session-db.chipster-host.com?

### HTTPS

TODO With Let's Encrypt certificates?

### Authentication
### JWT keys

TODO Generate and configure JWT keys to keep login tokens valid in `auth` restart.

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

TODO fi.csc.chispter.backup.Backup can take db dumps, encrypt and upload those to S3. BackupArchive can download those from S3 to a local disk on some other server.

#### Backup files

TODO FileBroker can encrypt and upload incremental file backups to S3. BackupArchive can download those from S3 to a local disk on some other server.

### Logging

TODO Collect logs with Filebeat (running in a sidecar container) and push them to Logstash

### Graphana

TODO Collect statistics from the admin Rest API, push them to InfluxDB and show in Grafana

### Monitoring and session replay tests

TODO Configure ReplayServer

### Customize front page, contact details and terms of use

TODO in app-*.html files in chipster-tools image in /home/user/chipster-tools/manual (?). File names are configured in secret-web-server-app.yaml

### Example sessions

 * check the password of `example_session_owner` from the auth (see  Admin view topic above)
 * login with that account and create same sessions
 * share them as read-only to user ID `everyone`

### Support request sessions

TODO
 * configure support email address on `session-worker`
 * check the password of `support_session_owner` from auth (see  Admin view topic above)
 * login with that account too see the support request sessions

### Remote management

TODO create k3s service account and use `kubectl` from your laptop

### K3s cluster

TODO 
 * How to handle images? Copy manually to each node or setup an image registry?
 * How to handle PVCs? Setup a NFS share or Longhorn?
 * How to scale the cluster up and down?
 * How to scale Chipster inside the cluster?

### Uninstall

Command `helm uninstall chipster` should delete all Kubernetes objects, except volumes. This is relatively safe to run when you want run the installation again, but want to keep the data on volumes. Use `kubectl delete pvc --all`, if you want to delete the volumes too.

If the Helm release is too badly broken, you can delete everything manually with `kubectl`.

```bash
for t in secret pod deployment ingress service statefulset pvc; do 
    kubectl delete $t --all
done
```


