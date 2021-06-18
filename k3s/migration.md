# Chipster in K3s Migration
## Update to v4.3

Before version v4.3 users' files were stored on file-broker and there could be only one of them making it difficult to add more storage space. In v4.3 a new service component called `file-storage` was introduced. There can be one or more file-storages. The file-broker is now only a stateless proxy passing requests to correct file-storages. There can be any number of file-brokers now too.

### Option 1: Start from Scratch

If you can remove the users' files, you can simply delete the whole installation and deploy it again:

```bash
helm uninstall chipster
kubectl delete pvc --all
git pull
bash generate-passwords.bash
bash deploy.bash -f ~/values.yaml
```
### Option 2: Offline Migration

There are many ways to do this, but if all your services run on the same host, probably to easiest is to install the new setup:

```bash
git pull
bash depbloy.bash -f ~/values.yaml
```

Then locate the the old and new storage volumes from the host under `/mnt/data/k3s/storage/` and move the files.

### Option 3: Online Migration

We did this for own installations in OpenShift, but we haven't gone through this in K3s. Here is the description of overall process:

- Deploy the new setup, but configure an additional file-storage, called `file-storage-old` and mount the old `file-broker-storage` volume there. Configure file-broker to use this for all old files, where the `storage` is `null` in the DB: `file-broker-storage-null: file-storage-old`.

- Chipster usage can be continue immediately. Old files are read from the file-storage-old, new files are written to new file-storage(s).
- Use admin view to copy files from file-storage-null to file-storage-0
- Remove file-storage-old

## Update to v4.4

We have updated the [Chipster installation instructions](README.md). Those now start from Ubuntu 20.04 and install Chipster, where all internet-facing containers are updated to Ubuntu 20.04. Only the `comp` container, running the actual analysis tools, stays in Ubuntu 16.04. That shouldn’t pose significant security risks, because comp's admin API is now disabled by default and otherwise comp is well protected behind other Chipster services. 
### Option 1: Install New Server (recommended)

You should update existing Chipster servers. Our recommended option is to install a new server and make sure that all necessary data is moved before removing the old server. The tools-bin package wasn’t updated at this point, so you can reuse your possible local copies of the latest tools-bin package (tools-bin version chipster-3.17.0).

The sessions from the old server can be moved either by following the [backup instructions](backup.md) or users can do it themselves by downloading the sessions to zip files from the old server and upload those to the new server.
### Option 2: Update Existing Server

We were able to update an old Chipster server, but this process is more risky for the data stored in Chipster. If the update fails for any reason, it may be difficult to copy the data from the broken server. This is also slower than the installation of new Chipster, at least excluding the download of the tools-bin package.

Update to Ubuntu 18.04:

```bash
sudo update
sudo upgrade
sudo do-release-upgrade
```

In fact we had some locale issues in the old Ubuntu and had to use this command instead:

```bash
sudo LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 do-release-upgrade
```

Update to Ubuntu 20.04:

```bash
sudo do-release-upgrade
```

Our server still had python2 installed causing problems in Ansible. Remove that first:

```bash
sudo apt remove python2
```

And then continue with the [Chipster update instructions](README.md#Updates).
