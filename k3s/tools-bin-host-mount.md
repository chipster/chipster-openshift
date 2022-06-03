# Mount tools-bin from the host
## Overview

These instructions show how to mount a tools-bin directory of the host to the container.
## Tools-bin

Make a directory for the tools-bin on the host. Let's make it on the volume in `/mnt/data` to have enough space. 

```bash
sudo mkdir -p /mnt/data/tools-bin/chipster-4.5.2
sudo chown $(whoami) /mnt/data/tools-bin/chipster-4.5.2
```

Change your `~/values.yaml` to mount tools-bin from this host directory. The tools-bin version number in the configuration file must match with the directory name above.

```yaml
toolsBin:
  version: chipster-4.5.2
  hostPath: /mnt/data/tools-bin
```

Deploy changes.

```bash
bash deploy.bash -f ~/values.yaml
```

Now you would have to download and extract the tools-bin packages. Replace all occurrances of "chipster-4.5.2" with your tools-bin version.

```
# make a temporary directory for the download packages
cd /mnt/data
sudo mkdir temp
sudo chown $(whoami) temp
cd temp

# get a list of packages
curl -s https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/ | grep chipster-4.5.2 | grep .tar.lz4$ > files.txt
# download packages
for f in $(cat files.txt); do wget https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/$f; done
cd ..

# install lz4
sudo apt install -y liblz4-tool

# extract packages 
for f in temp/*.tar.lz4; do lz4 -d $f -c - | tar -x -C tools-bin/chipster-4.5.2; done

# remove packages
rm -rf temp
```

Finally restart pods to enable all tools that were disabled before because of the missing files.

```
cd ~/git/chipster-openshift/k3s/
bash restart.bash
watch kubectl get pod
```

You can also take a look at [the download script](https://github.com/chipster/chipster-openshift/blob/master/k3s/helm/chipster/templates/download-tools-bin-job.yaml) that downloads the tools-bin package in pieces (and optionally in parallel).

If you already downloaded the tools-bin to a PVC, you could also locate the correct volume:

```bash
sudo du -sh /mnt/data/k3s/storage/*
```

And copy, symlink or move the files from there.