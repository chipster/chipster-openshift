# Deploy Chipster in RKE

## Introduction

If you have to install your own Kubernetes for Chipster, the recommended way is to use [K3s](README.md). Setting up Chipster on RKE makes sense only if you want to take advantage of an RKE cluster which is managed by someone else. 

Here are some notes about setting up an RKE node and Chipster on it, mostly for our internal testing.

## Install Docker

Start with an empty Ubuntu 20.04. Configure firewall to allow SSH and HTTP from your network.

[Configure Docker repository](https://github.com/chipster/chipster-openshift/blob/k3s/k3s/build-image.md#install-docker), but don't run the last line `apt install...` yet, because the current RKE doesn't support the latest Docker version 24.

Install previous Docker version:

```bash
sudo apt-get install -y docker-ce=5:23.0.6-1~ubuntu.20.04~focal docker-ce-cli containerd.io docker-compose-plugin
```

This command would show you the available versions:

```bash
apt-cache madison docker-ce
```

## Install RKE

```bash
mkdir rke
cd rke
wget https://github.com/rancher/rke/releases/download/v1.4.7/rke_linux-amd64
mv rke_linux-amd64 rke
chmod +x rke
./rke -version
```

Find out server's internal IP address:

```bash
ip a | grep 192
```

Create a file `cluster.yaml` and configure the address there:

```yaml
nodes:
    - address: 192.168.X.Y
      user: ubuntu
      role:
        - controlplane
        - etcd
        - worker

```

Create ssh key and allow rke to make ssh connections to this same machine:

```bash
ssh-keygen
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Allow docker without sudo:

```bash
sudo usermod -aG docker $USER
```

Activate the group change:

```bash
newgrp docker
```

Start RKE:

```bash
./rke up
```


If there are problems, delete the cluster and try again:

```bash
./rke remove
cluster.rkestate
```

Install `kubectl`:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

mkdir ~/.node
mv cp kube_config_cluster.yml .kube/config
```

[Install Helm](ansible/roles/install-helm/tasks/main.yml)
[Install utils](ansible/roles/install-utils/tasks/main.yml)

Install Local Path Provisioner:

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
```


## Deploy Chipster

   * [Install Ansible](prerequisites.md#install-ansible)
   * [Clone deployment scripts](prerequisites.md#clone-deployment-scripts)

Create file `~/values.yaml`:

```yaml
host: PUBLIC_IP_OR_HOST_NAME

image:
  localPullPolicy: Always
  chipsterImageRepo: docker-registry.rahti.csc.fi/chipster-images-beta/

ingress:
  kind: Ingress

auth-postgresql:
  persistence:
    storageClass: local-path

session-db-postgresql:
  persistence:
    storageClass: local-path
  
job-history-postgresql:
  persistence:
    storageClass: local-path

deployments:
  fileStorage:
    storageClassName: local-path
```

   * [Deploy Chipster](https://github.com/chipster/chipster-openshift/blob/k3s/k3s/README.md#deploy)