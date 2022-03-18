# Chipster in K3s prerequisites
## Operating system and remote connection

Let's assume that we have a ssh access to an Ubuntu 20.04 server. It doesn't matter if it is a physical hardwware or a virtual server.

The instructions assume that your account has passwordless sudo rights. TODO how to set it up?

## CPU and RAM

Each Chipster service requires about 0.5 GB of RAM, so Chipster itself uses about 8 GB of RAM. In addition you need 8 GB of memory for each job slot. Most tools use just one job slot. Search for `# SLOTS` in [chipster-tools](https://github.com/chipster/chipster-tools/search?q=%23+SLOTS&unscoped_q=%23+SLOTS) repository to see the tools that need more resources. Then calculate the amount of needed memory with the following formula:

```
JOB_SLOTS * 8 GB + 8 GB
```

Number of CPU cores is usually less critical, because nothing breaks if CPU is moderately oversubscribed. We usually have about 2 physical cores per 8 GB of RAM.

## Disk

Usually 20 GB is enough space for the root disk.

We need a lot of additinal storage space to store all the reference genomes, indexes and users' files.

 * mount at least 1 TB volume to the server
 * create a filesystem to the volume (assuming it's `/dev/vdb`)

 ```bash
 sudo mkfs.xfs -L data /dev/vdb
 ```

 * configure the volume mount

 ```bash
sudo bash -c "echo 'LABEL=data /mnt/data xfs defaults 0 0' >> /etc/fstab"
 ```

 * mount it

 ```bash
sudo mkdir -p /mnt/data
sudo mount -a
 ```

 * make sure you can see it

 ```bash
 $ df -h | grep data
/dev/vdb        1.0T   33M  1.0T   1% /mnt/data
 ```

 * create a symlink to use the volume for K3s volume storage

 ```bash
 sudo mkdir -p /mnt/data/k3s/storage /var/lib/rancher/k3s/
 sudo ln -s /mnt/data/k3s/storage /var/lib/rancher/k3s/storage
 ```

 * create a symlink to use the volume for container root and emptyDir volumes. We'll need a large emptyDir volume for temporary directory of the tools-bin download. K3s stores both root and emptyDir volumes in the same place.

 ```bash
sudo mkdir -p /mnt/data/k3s/pods /var/lib/kubelet
sudo ln -s /mnt/data/k3s/pods /var/lib/kubelet/pods
 ```

## Firewall

Make sure that you have firewall a (in the network / IaaS cloud or the Ubuntu's local iptables) that allows only 
* inbound access from your laptop to ports 22 (ssh), 80 (http) and optionally 443 for https
* outbound access to anything

* Optional [TLS (https) instructions](tls.md#firewall) will have a few additional requirements for the firewall

Especially make sure to protect the port 8472 that K3s would use for cummunicating with other K3s nodes (although we are going to install only one node now). 

TODO What is port 6443, is it important to protect that too?

If you don't want the server to have unrestricted outbound access, it's possible to [install Chipster behind a HTTP proxy](behind-proxy.md).
## Install Ansible

We'll install Ansible. It will be used to install other required programs.

```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
```

### Clone deployment scripts

Clone the deployment repository

```bash
cd
mkdir git
cd git
git clone https://github.com/chipster/chipster-openshift.git --branch k3s
cd chipster-openshift/k3s
```

From now on, please run all commands in this `k3s` directory unless told otherwise.

## Install Docker, K3s, Helm and other utils

We'll use Docker to build container images. K3s will be configured to also run images with Docker so the images are readily available in Docker after each build.

```bash
ansible-playbook ansible/install-deps.yml -i "localhost," -c local -e user=$(whoami)
```

Soon we'll use `kubectl` command, which requires an environment variable initialised in the `.bashrc` file. Logout and open a new ssh connection to initialise it now.

TODO Replace Docker with a userspace build system, e.g. [Kaniko](https://github.com/GoogleContainerTools/kaniko), and some image repository.

## Test Docker

Check that Docker is running.

```bash
$ sudo systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2020-02-12 14:33:24 UTC; 4min 46s ago
---
```

## Test `kubectl`

Check that you can now run `kubectl get node` without `sudo`.

## Test K3s and Helm

Generate an example project to a folder `nginx-test`.

```bash
helm create nginx-test
```

Deploy it. Replace `HOST_ADDRESS` with your server's DNS name.

```bash
helm install nginx-test nginx-test --set ingress.enabled=true --set ingress.hosts[0].paths[0].path="/" --set ingress.hosts[0].paths[0].pathType="ImplementationSpecific" --set ingress.hosts[0].host="HOST_ADDRESS"
```

If you don't have a DNS name for your host, you can set the `HOST_ADDRESS` parameter to an empty string `""`. In this case the example won't be able to print the correct address for you to open
in the next step, but just use the host's IP address there.

```bash
helm install nginx-test nginx-test --set ingress.enabled=true --set ingress.hosts[0].paths[0]="/"  --set ingress.hosts[0].paths[0].pathType="ImplementationSpecific" --set ingress.hosts[0].host=""
```

Open the HOST_ADDRESS in a browser on your laptop and check that you can see a page `Welcome to nginx!`. If there is any problem with this example deployment, it's a lot easier to investigate and fix it in this simple example setup, before starting to deploy Chipster.

When you are done, uninstall the test project from K3s and delete the folder.

```bash
helm uninstall nginx-test
rm -rf nginx-test
```

After checking that the test project above worked, you are ready to continue to the [Chipster installation](README.md#installation). 
