# Chipster in K3s prerequisites
## Operating system and remote connection

Let's assume that we have a ssh access to an Ubuntu 16.04 server. It doesn't matter if it is a physical hardwware or a virtual server.

The instructions assume that your account has passwordless sudo rights. TODO how to set it up?

## CPU and RAM

Each Chipster service requires about 0.5 GB of RAM, so Chipster itself uses about 8 GB of RAM. In addition you need 8 GB of memory for each job slot. Most tools use just one job slot. Search for `# SLOTS` in [chipster-tools](https://github.com/chipster/chipster-tools/search?q=%23+SLOTS&unscoped_q=%23+SLOTS) repository to see the tools that need more resources. Then calculate the amount of needed memory with the following formula:

```
JOB_SLOTS * 8 GB + 8 GB
```

Number of CPU cores is usually less critical, because nothing breaks if CPU is moderately oversubscribed. We usually have about 2 physical cores per job slot.

## Disk

We need a lot of storage space to store all the reference genomes, indexes and users' files.

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
sudo mkdir /mnt/data
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
* inbound access from your laptop to ports 22 (ssh), 80 (http) and maybe also 443 for https in the future
* inbound access from this machine itself (ports 80 and 443). In OpenStack's Security groups this would mean from the VM's floating IP address. TODO make it start without this
* outbound access to anything

Especially make sure to protect the port 8472 that K3s would use for cummunicating with other K3s nodes (although we are going to install only one node now). 

TODO What is port 6443, is it important to protect that too?

## Install Docker

We'll use Docker to to build container images.

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
```

Check that Docker is running.

```bash
$ sudo systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2020-02-12 14:33:24 UTC; 4min 46s ago
---
```

See [https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04) for more detailed installation instructions.

TODO Replace Docker with a userspace build system, e.g. [Kaniko](https://github.com/GoogleContainerTools/kaniko), and some image repository.

## Install K3s

```bash
curl -sfL https://get.k3s.io | sh -
```

Check that K3s works.

```bash
$ sudo k3s kubectl get node
NAME                  STATUS   ROLES    AGE   VERSION
HOST                  Ready    master   38s   v1.17.2+k3s1
```

Allow the current user to use `kubectl` command with K3s without `sudo`.

```bash
sudo chown $(whoami) ~/.kube
sudo bash -c "kubectl config view --raw " > ~/.kube/config
echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc; source ~/.bashrc
```

Check that you can now run `kubectl get node` also without `sudo`.

We'll use Docker to build container images. Let's configure K3s to also run images with Docker so the images are readily available in Docker after each build.

```bash
sudo sed -i 's/server \\/server --docker \\/' /etc/systemd/system/k3s.service
sudo systemctl daemon-reload
sudo systemctl restart k3s
```

## Install other utils

`yq` for parsing yaml files.

```bash
sudo snap install yq
```

`jq` for parsing json.

```bash
sudo apt install jq -y
```

`diceware` for generating human friendly passwords

```bash
sudo apt install python3-pip -y
pip3 install diceware
```

If you get an error `unsupported locale setting`, run a command `export LC_ALL=C` and then then the installation again.

## Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

Install a Helm chart repository called `stable`. The Postgresql chart will be installed from there.

```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```

More installation options are available in [https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/).

## Check that k3s and Helm work

TODO deploy nginx to test that k3s and helm work.

Generate an example project to a folder `nginx-test`.

```bash
helm create nginx-test
```

Deploy it. Replace `HOST_ADDRESS` with your server's DNS name or IP address.

```bash
helm install nginx-test nginx-test --set ingress.enabled=true --set ingress.hosts[0].paths[0]="/" --set ingress.hosts[0].host="HOST_ADDRESS"
```

Open the HOST_ADDRESS in a browser on your laptop and check that you can see a page starting with a title `Welcome to nginx!`. If there is any problem with this example deployment, it's a lot easier to investigate and fix it in this simple example setup, before  starting to deploy Chipster.

Uninstall the test project from K3s and delete the folder.

```bash
helm uninstall nginx-test
rm -rf nginx-test
```

After checking that the test project above worked, you are ready to continue to the [Chipster installation](README.md#installation). 