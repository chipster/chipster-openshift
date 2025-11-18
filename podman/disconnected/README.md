# Chipster in air gapped Podman

These instructions show how to run Chipster in https://sd-desktop.csc.fi/. Security measures of SD Desktop include:

- Air gap: Data can be transferred only through https://sd-connect.csc.fi/ .
- No root privileges: but there is Podman to run container images.

Although these instructions are written for SD Desktop, these can probably help a lot also in setting up Chipster to other similar disconnected environments.

## Preparations on an internet connected machine

Here are a few steps to package a Chipster in a format that is easy to transfer and use in the air gapped server. You can run these on your laptop or any server, where you have necessary command line tools, a decent internet connection, and enough temporary storage space.

Create three folders in SD Connect. In these examples we'll call them `chipster-repo`, `chipster-images` and `chipster-tools-bin`. However, each folder name in SD Connect has to be unique, so you have to modify these names somehow to find an unused name. For example, you can add some part of your project name or number to create unique folder names.

Only selected Chipster versions are tested in SD Connect. Check the latest tested image and tools-bin versions from variables in file https://github.com/chipster/chipster-openshift/blob/master/podman/disconnected/env.bash , and download those versions in the following sections.

### This repository

Check out a repository version that matches with your selected image version.

```bash
git clone --branch v4.18.2 https://github.com/chipster/chipster-openshift.git
tar -cf chipster-openshift.tar chipster-openshift
```

Upload `chipster-openshfit.tar` to your `chipster-repo` folder in SD Connect.

### Container images

Download a container image package of your selected version:

```bash
mkdir images
pushd images
curl https://a3s.fi/chipster-images/chipster-images-v4.18.2.tar.lz4 -O
```

Extract the package:

```bash
cat chipster-images-v4.18.2.tar.lz4 | lz4 -d | tar -x
```

Compress each file separately:

```bash
for f in *.tar; do
    cat $f | zstd > $f.zst
    rm $f
done
```

Delete the original package:

```bash
rm chipster-images-v4.18.2.tar.lz4
popd
```

Upload all files in the directory `images` to your SD Connect folder `chipster-images`. Upload seems to be significantly faster in Chrome (80 MiB/s) than in Safari (10 MiB/s).

If you want to use images from newer (but untested in SD Desktop) Chipster versions, see alternative instructions in https://github.com/chipster/chipster-openshift/blob/master/podman/disconnected/prepare/pull-images.md .

### Tools-bin

Download selected parts of tools-bin. This example downloads only one subdirectory (`R-3.2.3`). Remove `| grep R-3.2.3` from the command if you have enough storage space in SD Desktop for the whole tools-bin version.

```bash
version="chipster-4.17.4"
mkdir tools-bin
pushd tools-bin
for f in $(curl -s https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/$version$/parts/files.txt | grep R-3.2.3); do
    curl https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/$version$/parts/$f > $f
done
```

Compress with zstd

```bash
for f in *.tar; do
    cat $f | lz4 -d | pv | zstd > $(basename $f .lz4).zst
done
popd
```

Upload files from the directory `tools-bin` to your `chipster-tools-bin` folder in SD Connect.

## Copy data to the air gapped server

By default, SD Desktop creates a 200 GiB volume in `/media/volume`. We'll use this volume to store all files for Chipster.

Create a installation directory.

```bash
mkdir -p /media/volume/chipster
cd /media/volume/chipster
```

Find the Data Gateway icon in the SD Desktop to mount the files in SD Connect to your server. SD Desktop will mount these files to your virtual machine, but the exact path depends on your project number. We'll use `~/Project/SD-Connect/project_PROJECT_NUMBER` as an example in these instructions.

### Repository

Extract `chipster-openshift.tar` from the SD Connecct.

```bash
tar -xf ~/Project/SD-Connect/project_PROJECT_NUMBER/chipster-repo/chipster-openshift.tar
```

### Container images

Load container images from SD Connect to Podman:

```bash
bash chipster-openshift/podman/disconnected/load-images.bash ~/Project/SD-Connect/project_PROJECT_NUMBER/chipster-images
```

### Tools-bin

Extract the tools-bin packages.

```bash
mkdir -p tools-bin/chipster-4.17.4
cd tools-bin/chipster-4.17.4
for $f in ~/Project/SD-Connect/project_PROJECT_NUMBER/chipster-tools-bin/*.tar.zst; do
    echo $f
    cat $f | zstd -d | tar -x
done
```

## Setup Chipster

```bash
bash chipster-openshift/podman/disconnected/setup.bash
```

## Start Chipster

```bash
bash chipster-openshift/podman/disconnected/chipster-start.bash
```

This will start the Chipster server components and finally opens the Chipster user interface in a Firefox browser. Log in with the default account where username is `chipster` and password is `chipster`. Only users of your SD Desktop virtual machine can access this Chipster installation, so a proper password is not needed.

## How to keep your data safe

Download your analysis session as a zip file to your SD Desktop virtual machine often enough, for example daily. At some point the Chipster installation can break and the security requirements of the SD Desktop and your data can make it difficult to fix it. If this happens, you can try to repeat the previous steps and see if that fixes your Chipster installation.

When you have your session file stored on the virtual machine, you can always easily launch a new virtual machine in SD Desktop, install Chipster again and import your analysis session there. This is often easier than finding out what went wrong in the previous installation. SD Desktop does not let you export anything from the virtual machine (by design), so you have to ask the project manager of the CSC project to move your session file from the old virtual machine to the new virtual machine.
