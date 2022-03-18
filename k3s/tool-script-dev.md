# Tool script development
## Overview

Chipster comes with large selection of ready-made tool scripts. It's easy to edit or add new tools, if you want to customize your Chipster server
for specific analysis needs or even to a compeletely new field of science.

We would like to hear how Chipster is used, so we would encourage you to 
report your use case and your custom solutions for example on the [chipster-tech email list](https://chipster.rahtiapp.fi/contact). You can also fork our [chipster-tools repository](https://github.com/chipster/chipster-tools) in GitHub to publish your changes for others (preferably with and open source license).

[Building a new container image](build-image.md) from version control repository is a good way to ensure that all hosts in a Kubernetes cluster are running the same version and the history of all previous versions is stored. However, commits and builds are usually too slow for any interactive development work. 

To allow faster development cycle, these instructions show how to clone the chipster-tools repository to the host and then mount that directory to the toolbox container. This way you can easily edit the files on the host with your preferred editor. We use [Visual Studio Code](https://code.visualstudio.com/) [Remote Explorer](https://code.visualstudio.com/docs/remote/ssh) for our daily tool development work.

If you need changes to the tools-bin, you should also [mount tools-bin from the host](tools-bin-host-mount.md).

## Mount tool scripts from the host

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
## Reaload toolbox after tool script changes


When you have edited tool scirpts you have the trigger a tool reload in the toolbox. 

```bash
cd ~/git/chipster-tools/
bash reload.bash
```

The reload script has been a little bit unreliable. If the log timestamps
don't match with the UTC time, restart the whole toolbox container:

```bash
kubectl rollout latest deployment toolbox
```

## Try things in shell

TODO fix the tools-bin mount of the script

```bash
cd ~/git/chipster-tools/
bash comp-shell.bash
```

## Manual pages

Clone the tool manuals to the host and symlink them from the correct directory.

```bash
pushd ~/git
git clone https://github.com/chipster/chipster-tools.git
popd
```

Change your `~/values.yaml` to mount tool scripts from the host.

```yaml
tools:
  manualHostPath: /home/ubuntu/git/chipster-tools/manual
```

Deploy changes and wait until the pod has restarted.

```bash
bash deploy.bash -f ~/values.yaml
watch kubectl get pod
```

When you have edited manual pages, simply reload the browser to see the changes.

