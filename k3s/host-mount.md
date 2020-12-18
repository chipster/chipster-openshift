# Mount tools from the host
## Overview

These instructions show how to mount a directory of the host to the container.

## Tool scripts

Clone the tool scripts to the host and symlink them from the correct directory.

```bash
pushd ~/git
git clone https://github.com/chipster/chipster-tools.git
sudo mkdir -p /opt/chipster/toolbox
sudo chown -R $(whoami) /opt/chipster
ln -s ~/git/chipster-tools/tools /opt/chipster/toolbox
popd
```

Change your `~/values.yaml` to mount tool scripts from the host.

```yaml
tools:
  hostPath: /opt/chipster/toolbox/tools
```

Deploy changes.

```bash
bash deploy.bash -f ~/values.yaml
```

When you have edited tool scirpts you have the trigger a tool reload in the toolbox. The easiest way is to simply restart the toolbox again. 

```bash
kubectl rollout latest deployment toolbox
```

This will take only few seconds. If you want to make it even faster, you can create a new file in the container.

```bash
kubectl exec deployment/toolbox -it touch /opt/chipster/toolbox/.reload/touch-me-to-reload-tools
```

Restart toolbox once to make it watch this file.

```bash
kubectl rollout restart deployment toolbox
```

Now running the `kubectl ... touch` command above will trigger the toolbox reload instantaneously. You can see its results from the log file.

```bash
kubectl exec deployment/toolbox -it cat /opt/chipster/toolbox/logs/chipster.log
```

Or directly from the container output.

```bash
kubectl logs deployment/toolbox -f
```

## Tools-bin

Make a directory for the tools-bin on the host. Let's make it on the volume in `/mnt/data` to have enough space. Let's also symlink it to `/opt/chipster/tools` because our `R` installations are configured to run there.

```bash
sudo mkdir /mnt/data/tools-bin
sudo chown $(whoami) /mnt/data/tools-bin 
ln -s /mnt/data/tools-bin /opt/chipster/tools
```

Change your `~/values.yaml` to mount tools-bin from this host directory.

```yaml
toolsBin:
  hostPath: /opt/chipster/tools
```

Deploy changes.

```bash
bash deploy.bash -f ~/values.yaml
```

Now you would have to download and extract the tools-bin packages. 

```
# make a temporary directory for the download packages
cd /mnt/data
sudo mkdir temp
sudo chown $(whoami) temp
cd temp

# get a list of packages
curl -s https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/ | grep chipster-3.16.4 | grep .tar.lz4$ > files.txt
# download packages
for f in $(cat files.txt); do wget https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/$f; done
cd ..

# install lz4
sudo apt install -y liblz4-tool

# extract packages 
for f in temp/*.tar.lz4; do lz4 -d $f | tar -x -C tools-bin; done

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