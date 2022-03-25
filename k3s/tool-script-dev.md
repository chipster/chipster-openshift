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

## Runtimes

The `runtime` configures the environment where the tool should be run. You can find the default runtime configuration among all other
[default chipster configuration](https://github.com/chipster/chipster-web-server/blob/master/src/main/resources/chipster-defaults.yaml) by searching for a string `toolbox-runtime-`.

The default configuration may look something like this:

```yaml
toolbox-runtime-image: comp-16.04
toolbox-runtime-tools-bin-name: chipster-4.5.2
toolbox-runtime-tools-bin-path: /opt/chipster/tools
toolbox-runtime-command: /opt/chipster/tools/R-3.2.3/bin/R
toolbox-runtime-parameters: "--vanilla --quiet"
toolbox-runtime-job-factory: fi.csc.chipster.comp.r.RJobFactory
```

Let's go through these configuration options one by one.

There are many ways to provide code and files for a Chipster tool. First of all, you can select the container image with configuration option `toolbox-runtime-image`. This decides 
the operating sytem where the tool will be run. Also packages from operating sytem package manager (e.g. `apt` in Ubuntu) is easiest to install directly to this container image. At the moment the container image must include also the program `SingleShotComp` which takes care of communication with Chipster APIs. The image repository is set in scheduler with `scheduler-bash-image-repository`.

Container images are not suited for large data files. Chipster's way to provide larger
collection of program binaries and reference data is a so called `tools-bin` directory. The appropriate tools-bin can be selected with a configuration option `toolbox-runtime-tools-bin-name`. At the moment all Chipster tools are provided in one
large tools-bin directory and this configuration option is used to switch between
different versions when the Chipster is updated. Additional configuration option `toolbox-runtime-tools-bin-path` defines the path where the tools-bin directory is mounted.

Third and easiest way to provide code for the tool is the tool script itself. The tool script is a text file which needs an interpreter program to be run. Tool scripts
are written in R or Python language and the corresponding interpreter program is set with a configuration option `toolbox-runtime-command`. In the example above, in this case the interpreter program comes from the tools-bin directory, because the path points under the tools-bin mount `/opt/chipster/tools`. If the interpreter program requires additional parameters, those can be given with `toolbox-runtime-parameters`. 

Finally, each script language needs its own way of injecting that parameter variables and recognising errors. These functionalities are provided for the supported languages with a JobFactory, selected by configuration option `toolbox-runtime-job-factory`.

Sometimes a group of tools require their own environment. It's easy to create an own runtime for those tools. Simply invent a name for the new runtime (e.g. `R-4.1.1`) and append a dash "`-`" and that name to the end of all configuration options that you want to override. This is how it would look in your `~/values.yaml`:

```yaml
deployments:
  toolbox:
    configs:
      toolbox-runtime-command-R-4.1.1: /opt/chipster/tools/R-4.1.1/bin/R
      toolbox-runtime-image-R-4.1.1: comp-20.04-r-deps
```

You don't have to override all configuration options, because Chipster will automatically fall back to the default options. For example, this runtime `R-4.1.1` would use the container image set in `toolbox-runtime-image`, because it's not ovverriden here. If you want to remove some default value in your own runtime, simply set it to an empty string `""`.

Deploy the configuration, restart toolbox and check the logs:

```bash
bash deploy.bash -f ~/values.yaml 
kubectl rollout restart deployment/toolbox
kubectl logs deployment/toolbox --follow
```

A custom runtime is enabled in a tool script simply by referencing its name:

```
# RUNTIME R-4.1.1
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

