# Chipster in K3s

## Overview

These instructions show how to install the Chipster web app v4 to an Ubuntu server. 

Chipster is based on microservice architecture. There is about a dozen different services, but each of service tries to be relatively simple and independent. Each service is run in its own container. The containers are orchestrated with [Lightweight Kubernetes K3s](https://k3s.io).

The user interface in the v4 Chipster is a single-page-application (SPA) running in the user's browser. Commnad line client and Rest APIs are also available.

## Status

Chipster v4 is under heavy development and is still a bit rough around the edges. Nevertheless, it should be nicely usable for the end users running real analysis jobs. We are running it ourselves for that purpose. Many architectural choices are based on the old tried-and-tested Chipster v3.

However, tha same cannot be said about these installation instructions. These are the first attempt to show how to get the Chipster running. 

To get started as fast as possible, these instructinos assume that were are setting up a new single-node server. At this point we don't promise to offer complete instructions for updating this server to new Chipster versions later. Especially migrating the user's sessions and files from one version to another is not always trivial. We do try to provide the critical pointers, because we are migrating our own installations anyway. 

The same goes for many other aspcects of configuring and maintaining the server. Many empty titles are added to highlight different aspects that you should considered when running a server in the public internet. Luckily many of these topics are not actually specific to Chipster (e.g. how to setup https or more nodes for K3s). Pull requests for improving this documenation are very much welcome.

These instructions aim to build everything starting from the plain files in GitHub. It's little bit more work, but it allows you to change any part of the system easily. This will be useful now in these early phases of the project. Maybe later we could provide compiled code packges, container images and Helm Charts in public repositories making the initial installation easier, but raising the bar for custom modifications.

## Why k3s

K3s is a Lightweight Kubernetes, effectively a container cloud platform. Do we really need the cointainer cloud platform to run a few server processes on single host? Not really, you could checkout the code yourself and follow the Dockerfiles to see what operating system packages and what kind of folder structure is needed for each service, how to compile the code and how to start the processes. Add some form of reverse proxy to terminate HTTPS (e.g. Apache or nginx) and some process monitoring (Java Service Wrapper or systemd) and you are done.

However, k3s offers standardized way of doing all that and we don't want to implement ourselves functionalities that are already offered in the standard the container cloud platforms, like HTTPS termination. K3s allows us to run small-scale Chipster in very similar environment, that we know well from our larger production installations. We aim to rely even more on the Kubernetes features in the future. For example, it would be nice to run each Chipster job in its own container. This would make it easier to manage tool dependencies and improve security. This kind of changes are probably a lot eaiser in the future, if the Chispter is already running in some kind of container platform.

## Installation
### Requirements
#### Access

Let's assume that we have a ssh access to an Ubuntu 16.04 server. It doesn't matter if it is a physical hardwware or a virtual server.

The instructions assume that your account has passwordless sudo rights. TODO how to set it up?

We need a lot of storage space to store all the reference genomes, indexes and users' files.

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
 * create a symlink to use the volume for K3s volume storage
 ```bash
 sudo mkdir -p /mnt/data/k3s/storage /var/lib/rancher/k3s/
 ln -s /mnt/data/k3s/storage /var/lib/rancher/k3s/storage
 ```

 * create a symlink to use the volume for container root and emptyDir volumes. We'll need a large emptyDir volume for temporary directory of the tools-bin download. K3s stores both root and emptyDir volumes in the same place.

 ```bash
sudo mkdir -p /mnt/data/k3s/pods /var/lib/kubelet
ln -s /mnt/data/k3s/pods /var/lib/kubelet/pods
 ```

#### Firewall

Make sure that you have firewall a (in the network / IaaS cloud or the Ubuntu's local iptables) that allows only 
* inbound access from your laptop to ports 22 (ssh), 80 (http) and maybe also 443 for https in the future
* inbound access from this machine itself (ports 80 and 443). In OpenStack's Security groups this would mean from the VM's floating IP address. TODO make it start without this
* outbound access to anything

Especially make sure to protect the port 8472 that K3s would use for cummunicating with other K3s nodes (although we are going to install only one node now). 

TODO What is port 6443, is it important to protect that too?

#### Hardware Resources

Each Chipster service requires about 0.5 GB of RAM, so Chipster itself uses about 8 GB of RAM. In addition you need 8 GB of memory for each job slot. Most tools use just one job slot. Search for `# SLOTS` in [chipster-tools](https://github.com/chipster/chipster-tools/search?q=%23+SLOTS&unscoped_q=%23+SLOTS) repository to see the tools that need more resources. Then calculate the amount of needed memory with the following formula:

```
JOB_SLOTS * 8 GB + 8 GB
```

Number of CPU cores is usually less critical, because nothing breaks if CPU is moderately oversubscribed. We usually have about 2 physical cores per job slot.

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

See [https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04) for more detailed installation instructions.

### Install K3s

```bash
curl -sfL https://get.k3s.io | sh -
# Check for Ready node
sudo k3s kubectl get node
```

Allow the current user to use `kubectl` command with K3s without `sudo`.

```bash
sudo bash -c "kubectl config view --raw " > ~/.kube/config
echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc; source ~/.bashrc
```

We'll use Docker to build container images. Let's configure K3s to also run images with Docker so the images are readily available in Docker after each build.

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

Install a Helm chart repository called `stable`. The Postgresql chart will be installed from there.

```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
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

### Clone deployment scripts

Clone the deployment repository

```bash
mkdir ~/git
cd git
git clone https://github.com/chipster/chipster-openshift.git
cd chipster-openshift/k3s
```

From now on, please run all commands in this `k3s` directory unles told otherwise.

### Build Images

Building container images will accomplish the following tasks:

* Checkout code repositories
* Compile code
* Install operating system packages

In effect we are executing commands defined in Dockerfiles. Most services will run with a minimal image with only Java and Chipster installed on top of Ubuntu, whereas the comp (i.e. analysis) service requires a huge number of operating system
packages.

Let's build the images. 

```bash
bash build-image.bash --all
```

This will take about half an hour.

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

### Deploy

First we generate passwords. 

Helm doesn't seem to have a standard way for handling passwords. Our solution is to have a separate bash script which generates the passwords and stores them in a Kubernetes `secret`. The passwords are stored in a same format as the `values.yaml` in the Chipster Helm chart.

```bash
bash generate-passwords.bash
```

Download dependencies.

```bash
helm dependency update helm/chipster
```

Then we deploy the Chipster itself. Replace `HOST_ADDRESS` with host machine's public IP address or DNS name.

The script takes the passwords from the `passwords` secret that we just created.

```bash
bash deploy.bash --set host=HOST_ADDRESS
```

See when pod's are running (hit Ctlr + C to quit).

```bash
watch kubectl get pod
```

The `deploy.bash` script above showed you the address of the Chipster web app, which you can open in your browser. It will also print the credentials of the `chipster` account that you can use to log in to the app.

If something goes wrong in the deployment and you want to start from scratch, see the [uninstall](#uninstall) chapter.

Most tools wont work yet, because we haven't downloaded the tools-bin package. Let's make a small test before that to make sure that all the basic Chipster work. Upload some file to Chipster and run a tool `Misc` -> `Tests` -> `Test data input and output in Python`. If the result file appears in the Workflow view after few seconds, you can continue to the next chapter. If you encounter any errors, please try to solve them before continuing, because it's a lot easier and faster to change the deployment before you start the hefty tools-bin download.

We'll get to the tools-bin download soon, but let's take a quick look to the configuration system and updates first.

## Configuration and Maintenance

### Getting started with k3s

Please see [Getting started with k3s](getting-started-with-k3s.md) for K3s basics.

### Helm chart values

Deployment settings are defined in the `helm/chipster/values.yaml` file. You can override any of these values by passing `--set KEY=VALUE` arguments to the `deploy.bash` script (in addition to all the previous arguments), just like you have already done with the host name.

For example, to create a new user account `john` with a password `verysecretpassword`, you would check the file `values.yaml` to see which object needs to modified. 
You would run the `deploy.bash` scripte then again with an additional argument:

```bash
--set users.john.password=verysecretpassword
```

More instructions about the `--set` argument can be found from the documentation of the command [`helm install`](https://helm.sh/docs/intro/using_helm/).

Managing all the changes in the arguments becomes soon overwhelming. It's better to create your own `values.yaml`, to your home directory for instance, which could look like this:

```yaml
host: HOST 

users:
  john:
    password: "verysecretpassword"
```

You can then simply pass this file to the deployment script.

```bash
bash deploy.bash -f ~/values.yaml
```

If you need to debug this process, you can run the above command with `--debug --dry-run` options to see how Helm processes the values.

### Chipster settings

All Chipster configuration options can be found from the [chipster-defaults.yaml](https://github.com/chipster/chipster-web-server/blob/master/src/main/resources/chipster-defaults.yaml). The `values.yaml` (explained in the previous chapter) has a `deployments.CHIPSTER_SERVICE.configs` map for each Chipster service, where you can set Chipster configuration key-value pairs. 

Command line argument format:

```bash
--set deployments.comp.configs.comp-max-jobs=5
```

YAML file format:

```yaml
deployments:
  comp:
    configs:
      comp-max-job: 5
```

Please note that two-word Chipster service names like `file-broker` are written with `camelCase` in the `deployments` map, i.e. `fileBroker`.

### Updates

If you are going to maintain a Chipster server, you should subscribe at least to the [chipster-annoncements](https://chipster.csc.fi/contact.shtml) email list to get notifications about new features and critical vulnerabilities. Consider subsribing to the [chipster-tech](https://chipster.csc.fi/contact.shtml) list too to share your experiences and learn from others.

TODO How to follow vulnerabilities in Ubuntu, Helm and K3s?

If you have just installed Chipster, you can simply skim through this chapter now and return here when it's time to update your installation.

Update operating system packages on the host.

```bash
sudo apt update
sudo apt upgrade -y
```

TODO How to update Helm and K3s?

Pull latest changes from the deployment repository.

```bash
git pull
```

Rebuild images.

```bash
bash build-image.bash --all
```

Upate the deployment (assuming that you have created your own `values.yaml`).

```bash
bash deploy.bash -f ~/values.yaml
```

Restart all pods.

```bash
bash restart.bash
```

### Download the tools-bin package

When you have checked that the Chipster itself works, you can start the tools-bin download. Simply run the deployment again, but set the tools-bin version this time.

TODO How to find out available tools-bin versions?

Command line argument format
```bash
bash deploy.bash OTHER_ARGS --set toolsBin.version=chipster-3.15.6
```

YAML file format:
```yaml
toolsBin:
  version: chipster-3.15.6
```

That will also will print you insctructions for how to follow the progress of the download and how to restart pods when it completes.

### Admin view

 * check the password of `admin` user account from the auth

 ```bash
 kubectl exec deployment/auth -it -- cat security/users
 ```

 * when logged in with that account, there is `Admin` link in the top bar of the web app. Click that link to see the Admin view

### Custom DB queries

Postgres databases are defined as a dependency of the Chipster Helm chart. When you deploy the Chipster Helm chart, also the databases are deployed.

If you want to make custom queries to the databases, you can run the `psql` client program in the database container.

```bash
kubectl exec statefulset/chipster-session-db-postgresql -it -- bash -c 'psql postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost/$POSTGRES_DB'
```

Single quotes (`'`) are important so that your local shell doesn't try to expand the variables, which are only defined inside of the container.

### Wildcard DNS

TODO Now the Ingress is passing requests from different subpaths like http://HOST/auth and http://HOST/file-broker to different services and rewriting the request paths. How to configure K3s and a wildcard DNS record, so that we could use web-server.HOST and session-db.HOST addresses instead?

### HTTPS

TODO With Let's Encrypt certificates? Then change the service addressess in secrets.

### Authentication
### JWT keys

Chipster services ´auth´ and ´session-db´ create authentication tokens. These are JWT tokens that are signed with a private key. Other Chipster services can request the corresponding public key from the Rest API of these services to validate these tokens. The private key is generated in `generate-passwords.bash` and must be kep secret. If you have to invalidate all current authentication tokens, you can generate new private keys.

#### OpenID Connect

TODO Works e.g. with Google authentication, but then all Google accounts have full user permissions in Chipster. Access can be restricted with firewalls or by using other more exclusive OpenID Connect providers.

#### LDAP authentication

TODO A similar jaas config should still work like in the old Chipster v3, but it hasn't been tested.

#### File authentication

TODO A file security/users on `auth`, just like in the old Chipster v3. New users can be added there through `values.yaml`.

### Backups
#### Backup deployment configuration

Take a copy of your ´~/values.yaml´.

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

TODO copy kubectl configuration from the host and use `kubectl` from your laptop

### K3s cluster

TODO 
 * How to handle images? Copy manually to each node or setup an image registry?
 * How to handle PVCs? Setup a NFS share or Longhorn?
 * How to scale the cluster up and down?
 * How to scale Chipster inside the cluster?

### Uninstall

Command `helm uninstall chipster` should delete all Kubernetes objects, except volumes. This is relatively safe to run when you want run the installation again, but want to keep the data volumes. Use `kubectl delete pvc --all`, if you want to delete the volumes too.

The `helm uninstall` command gives you almost a fresh start with one caveat. The databases store their password on their volume. If you generate the passwords again, the databases won't accept the new passwords. In the early phases when you don't have anything valuable in the databases, it's easiest to simply delete the database volumes.

If the Helm release is too badly broken, you can delete everything manually with `kubectl`.

```bash
for t in job deployment statefulset pod secret ingress service pvc; do  
    kubectl delete $t --all
done
```


