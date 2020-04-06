# Chipster in K3s migration
## Update to v4.3

Before version v4.3 users' files were stored on file-broker and there could be only one of them making it difficult to add more storage space. In v4.3 a new service component called `file-storage` was introduced. There can be one or more file-storages. The file-broker is now only a stateless proxy passing requests to correct file-storages. There can be any number of file-brokers now too.

### Option 1: Start from scratch

If you can remove the users' files, you can simply delete the whole installation and deploy it again:

```bash
helm uninstall chipster
kubectl delete pvc --all
git pull
bash generate-passwords.bash
bash deploy.bash -f ~/values.yaml
```
### Option 2: Offline migration

There are many ways to do this, but if all your services run on the same host, probably to easiest is to install the new setup:

```bash
git pull
bash depbloy.bash -f ~/values.yaml
```

Then locate the the old and new storage volumes from the host under `/mnt/data/k3s/storage/` and move the files.

### Option 3: Online migration

We did this for own installations in OpenShift, but we haven't gone through this in K3s. Here is the description of overall process:

- Deploy the new setup, but configure an additional file-storage, called `file-storage-old` and mount the old `file-broker-storage` volume there. Configure file-broker to use this for all old files, where the `storage` is `null` in the DB: `file-broker-storage-null: file-storage-old`.

- Chipster usage can be continue immediately. Old files are read from the file-storage-old, new files are written to new file-storage(s).
- Use admin view to copy files from file-storage-null to file-storage-0
- Remove file-storage-old
