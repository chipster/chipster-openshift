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

Now you would have to download the tools-bin package. In a perfect world that would be just a matter of running a few commands.

```bash
cd /opt/chipster/tools
wget http://bio.nic.funet.fi/pub/sci/molbio/chipster/dist/virtual_machines/CHIPSTER_VERSION/tools/tools.tar.gz
tar -zxf tools.tar.gz -C /opt/chipster/tools/
```

If you are not that lucky, you can take a look at [the download script](https://github.com/chipster/chipster-openshift/blob/master/k3s/helm/chipster/templates/download-tools-bin-job.yaml) that downloads the tools-bin package in pieces (and optionally in parallel).

You can also take a look at the [instructions of the old Chipster](https://github.com/chipster/chipster/wiki/TechnicalManual#download-tools-package-manually).

If you already downloaded the tools-bin to a PVC, you could also locate the correct volume:

```bash
sudo du -sh /mnt/data/k3s/storage/*
```

And copy, symlink or move the files from there.