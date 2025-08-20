# Mount tools-bin from the host

## Overview

These instructions show how to mount a tools-bin directory of the host to the container.

## Tools-bin

Use to following command to check the available tools-bin versions. Don't worry if the latest tools-bin version there is older than the latest Chipster version. It means only that the tools-bin package hasn't changed since that version.

```bash
$ aws s3 --endpoint-url https://a3s.fi --no-sign-request ls s3://chipster-tools-bin
...
                           PRE chipster-4.6.5/
                           PRE chipster-4.6.6/
                           PRE chipster-4.9.0/
```

Make a directory for the tools-bin on the host. Let's make it on the volume in `/mnt/data` to have enough space. Replace the version numbers in this example (4.9.0) with the latest version number.

```bash
TOOLS_BIN_VERSION="chipster-4.9.0"

sudo mkdir -p /mnt/data/tools-bin/$TOOLS_BIN_VERSION
sudo chown $(whoami) /mnt/data/tools-bin/$TOOLS_BIN_VERSION
```

Change your `~/values.yaml` to mount tools-bin from this host directory. The tools-bin version number in the configuration file must match with the directory name above.

```yaml
toolsBin:
  version: chipster-4.9.0
  hostPath: /mnt/data/tools-bin
```

Deploy changes.

```bash
bash deploy.bash -f ~/values.yaml
```

Soon we will download and extract the tools-bin packages. Let's prepare a few folders for it and install a program for extracting .lz4 compressed files.

```bash
# make a temporary directory for the download packages
cd /mnt/data
sudo mkdir temp
sudo chown $(whoami) temp

# install lz4
sudo apt install -y liblz4-tool
```

Downlaod the list of packages. Variable $TOOLS_BIN_VERSION must be set beforehand.

```bash
curl -s https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/$TOOLS_BIN_VERSION/parts/files.txt | grep .tar.lz4$ > temp/files.txt

```

If you have lot of free disk space, you can first download all files and then extract them. Variable $TOOLS_BIN_VERSION must be set beforehand.

```bash
cd temp

# download packages
for f in $(cat files.txt); do 
  if ! wget https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/$TOOLS_BIN_VERSION/parts/$f; then 
    break
  fi
done
cd ..

# extract packages
for f in temp/*.tar.lz4; do lz4 -d $f -c - | tar -v -x -C tools-bin/$TOOLS_BIN_VERSION; done

# remove packages
rm -rf temp
```

Or if you are tight on disk space, you can downlaod and extract the files one by one. Variable $TOOLS_BIN_VERSION must be set beforehand.

```bash

for f in $(cat temp/files.txt); do
  # download
  if ! wget https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/$TOOLS_BIN_VERSION/parts/$f -O temp/$f ; then
    break
  fi

  # extract
  lz4 -d temp/$f -c - | tar -x -C tools-bin/$TOOLS_BIN_VERSION

  # remove
  rm temp/$f
done
```

Finally restart pods to enable all tools that were disabled before because of the missing files.

```bash
cd ~/git/chipster-openshift/k3s/
bash restart.bash
watch kubectl get pod
```

If you already downloaded the tools-bin to a PVC, you could also locate the correct volume:

```bash
sudo du -sh /mnt/data/k3s/storage/*
```

And copy, symlink or move the files from there.
