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

## Update to v4.4 (Ubuntu 20.04)

We have updated the [Chipster installation instructions](README.md). Those now start from Ubuntu 20.04 and install Chipster, where all internet-facing containers are updated to Ubuntu 20.04. Only the `comp` container, running the actual analysis tools, stays in Ubuntu 16.04. That shouldn’t pose significant security risks, because comp's admin API is now disabled by default and otherwise comp is well protected behind other Chipster services.

### Option 1: Install New Server (recommended)

You should update existing Chipster servers. Our recommended option is to install a new server and make sure that all necessary data is moved before removing the old server. The tools-bin package wasn’t updated at this point, so you can reuse your possible local copies of the latest tools-bin package (tools-bin version chipster-3.17.0).

The sessions from the old server can be moved either by following the [backup instructions](backup.md) or users can do it themselves by downloading the sessions to zip files from the old server and upload those to the new server.

### Option 2: Update Existing Server

We were able to update an old Chipster server, but this process is more risky for the data stored in Chipster. If the update fails for any reason, it may be difficult to copy the data from the broken server. This is also slower than the installation of new Chipster, at least excluding the download of the tools-bin package.

Update to Ubuntu 18.04:

```bash
sudo apt update
sudo apt upgrade
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

## Update to K3s v1.32.4

Since Chipster version v4.15.0, the Ansible playbook in the update instructions will update the K3s from version `v1.26.4` to `v1.32.4`. The new K3s will have different API version for the IngressRoute object. After K3s has been updated, Helm and kubectl cannot manage the old IngressRoute objects anymore.

Uninstall Chipster before the K3s update to prevent problems later:

```bash
helm uninstall chipster
```

This didn't delete the data on our test servers, but take the necessary precautions condsidering backups.

And then continue with the [Chipster update instructions](README.md#Updates).

### Recovering from Failed K3s v1.32.4 Update

If you didn't uninstall Chipster before upgrading K3s, you will get a error like this:

```
$ bash deploy.bash -f ~/values.yaml
Error: UPGRADE FAILED: unable to build kubernetes objects from current release manifest: [resource mapping not found for name: "chipster" namespace: "" from "": no matches for kind "IngressRoute" in version "traefik.containo.us/v1alpha1"
ensure CRDs are installed first, resource mapping not found for name: "chipster-stripprefix" namespace: "" from "": no matches for kind "Middleware" in version "traefik.containo.us/v1alpha1"
...
```

Here are the steps the worked on our test server. This didn't delete the data in our tests. List all secrets:

```bash
kubectl get secret
```

Delete all helm releases that you found with the previous command:

```bash
kubectl delete secret sh.helm.release.v1.chipster.v8
kubectl delete secret sh.helm.release.v1.chipster.v7
...
kubectl delete secret sh.helm.release.v1.chipster.v1
```

After this we were able to to deploy Chipster again:

```bash
bash deploy -f values.yaml
```

## Update to Ubuntu 24.04

The table of different Chipster versions and corresponding Ubuntu and K3s versions:

| Chipster version  | Ubuntu on K3s host | Ubuntu in Chipster containers (except comp) | Ubuntu in comp containers | K3s version |
| ----------------- | ------------------ | ------------------------------------------- | ------------------------- | ----------- |
| <= v4.13.15       | 20.04              | 20.04                                       | 16.04 or 20.04            | v1.26.4     |
| v4.14.0 - v4.14.2 | 20.04              | 24.04                                       | 16.04, 20.04 or 24.04     | v1.26.4     |
| >= v4.15.0        | 24.04              | 24.04                                       | 16.04, 20.04 or 24.04     | v1.32.4     |

Until Chipster version v4.13.15, the Chipster containers (except comp) were running Ubuntu 20.04. If you installed any version between v4.14.0 and v4.14.2, those containers were running Ubuntu 24.04, but the K3s host was still running older Ubuntu 20.04. We have now updated the [Chipster installation instructions](README.md) in Chipster version v4.15.0. Those now start also from Ubuntu 24.04 on the K3s host. If you are running a Chipster version v4.14.2 or older, you should update K3s (see previous chapter) and Ubuntu on the K3s host. The next two sections show you two options for doing it.

Analysis tools in `comp` containers run in Ubuntu 16.04, Ubuntu 20.04 or Ubuntu 24.04. That shouldn’t pose significant security risks, because comp is well protected behind other Chipster services.

When a job is started, the comp gets an access token only for the session where it's run. The most important attack vectors for the comp are the input files and parameters, but the user who can change the parameters and input files, can already access all the data in the session anyway.

### Option 1: Install New Server (recommended)

Our recommended option is to install a new server and make sure that all necessary data is moved before removing the old server. The tools-bin package wasn’t updated at this point, so you can reuse your possible local copies of the latest tools-bin package (tools-bin version chipster-4.9.0).

The sessions from the old server can be moved either by following the [backup instructions](backup.md) or users can do it themselves by downloading the sessions to zip files from the old server and upload those to the new server.

### Option 2: Update Existing Server

We were able to update an old Chipster server, but this process is more risky for the data stored in Chipster. If the update fails for any reason, it may be difficult to copy the data from the broken server. This is also slower than the installation of new Chipster, at least excluding the download of the tools-bin package.

Update to Ubuntu 22.04:

```bash
sudo apt update
sudo apt upgrade -y
sudo shutdown -r now
sudo do-release-upgrade
```

Update to Ubuntu 24.04:

```bash
sudo do-release-upgrade
```

And then continue with the [Chipster update instructions](README.md#Updates), if you didn't do that already.


## Replace Bitnami image 
### Update to v4.18.0

Chipster has used Bitnami image to run its PostgreSQL databases until version v4.17.5. Unfortunately Bitnami has decided to stop providing this image after September 29th: https://hub.docker.com/r/bitnami/postgresql . 

This is fixed in Chipster version v4.18.0. Do the following steps to update. This shouldn’t delete your sessions, but normal backup precautions are of course recommended when making changes to databases.

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> a296af3 (Take backup copy of passwords)
1. Take a backup copy of the passwords Secret

```bash
kubectl get secret passwords -o json > ~/passwords-backup.json
```

2. Delete old Bitnami chart (otherwise Helm will deploy it with default name `chipster-postgresql`):
<<<<<<< HEAD
=======
1. Delete old Bitnami chart (otherwise Helm will deploy it with default name `chipster-postgresql`):
>>>>>>> e24fd92 (Replace Bitnami chart)
=======
>>>>>>> a296af3 (Take backup copy of passwords)
=======
1. Delete old Bitnami chart (otherwise Helm will deploy it with default name `chipster-postgresql`):
>>>>>>> e24fd92 (Replace Bitnami chart)

```bash
rm helm/chipster/charts/postgresql-16.0.1.tgz
```

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
3. Delete Services of old databases:
=======
2. Delete Services of old databases:
>>>>>>> e24fd92 (Replace Bitnami chart)
=======
3. Delete Services of old databases:
>>>>>>> a296af3 (Take backup copy of passwords)
=======
2. Delete Services of old databases:
>>>>>>> e24fd92 (Replace Bitnami chart)

```bash
kubectl delete service/chipster-auth-postgresql service/chipster-job-history-postgresql service/chipster-session-db-postgresql
```

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
4. Delete StatefulSets of old databases:
=======
3. Delete StatefulSets of old databases:
>>>>>>> e24fd92 (Replace Bitnami chart)
=======
4. Delete StatefulSets of old databases:
>>>>>>> a296af3 (Take backup copy of passwords)
=======
3. Delete StatefulSets of old databases:
>>>>>>> e24fd92 (Replace Bitnami chart)

```bash
kubectl delete sts/chipster-auth-postgresql sts/chipster-job-history-postgresql sts/chipster-session-db-postgresql
```

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
5. (Optional) If you have used hostPath volumes for your databases like shown in https://github.com/chipster/chipster-openshift/blob/k3s/k3s/change-k3s-version.md#configure-hostpath-volumes , the new configuration is much simpler. If you have the following in your ~/values.yaml, it can be removed:
=======
4. (Optional) If you have used hostPath volumes for your databases like shown in https://github.com/chipster/chipster-openshift/blob/k3s/k3s/change-k3s-version.md#configure-hostpath-volumes , the new configuration is much simpler. If you have the following in your ~/values.yaml, it can be removed:
>>>>>>> e24fd92 (Replace Bitnami chart)
=======
5. (Optional) If you have used hostPath volumes for your databases like shown in https://github.com/chipster/chipster-openshift/blob/k3s/k3s/change-k3s-version.md#configure-hostpath-volumes , the new configuration is much simpler. If you have the following in your ~/values.yaml, it can be removed:
>>>>>>> a296af3 (Take backup copy of passwords)
=======
4. (Optional) If you have used hostPath volumes for your databases like shown in https://github.com/chipster/chipster-openshift/blob/k3s/k3s/change-k3s-version.md#configure-hostpath-volumes , the new configuration is much simpler. If you have the following in your ~/values.yaml, it can be removed:
>>>>>>> e24fd92 (Replace Bitnami chart)

```yaml
auth-postgresql:
  primary:
    persistence:
      existingClaim: "auth-pvc-volume-postgres"

session-db-postgresql:
  primary:
    persistence:
      existingClaim: "session-db-pvc-volume-postgres"

job-history-postgresql:
  primary:
    persistence:
      existingClaim: "job-history-pvc-volume-postgres"
```

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> a296af3 (Take backup copy of passwords)
6. After this, follow the usual instructions in https://github.com/chipster/chipster-openshift/blob/k3s/k3s/README.md#updates to update to version v4.18.0. When running “bash generate-passwords.bash”, you will see little bit of extra text telling that the three database passwords are migrated to their new names. 

7. When you have completed the update and you can still open your old sessions in Chipster, you can delete the backup copy of the passwords Secret:

```bash
rm ~/passwords-backup.json
```
<<<<<<< HEAD

### Troubleshooting

If you see an error like this, see steps 3 and 4.
=======
=======
>>>>>>> e24fd92 (Replace Bitnami chart)
5. After this follow the usual instructions in https://github.com/chipster/chipster-openshift/blob/k3s/k3s/README.md#updates to update to version v4.18.0. When running “bash generate-passwords.bash”, you will see little bit of extra text telling that the three database passwords are migrated to their new names. 

### Troubleshooting

If you see an error like this, see steps 2 and 3.
<<<<<<< HEAD
>>>>>>> e24fd92 (Replace Bitnami chart)
=======

### Troubleshooting

If you see an error like this, see steps 3 and 4.
>>>>>>> a296af3 (Take backup copy of passwords)
=======
>>>>>>> e24fd92 (Replace Bitnami chart)

```
Error: UPGRADE FAILED: cannot patch "chipster-auth-postgresql" with kind Service: Service "chipster-auth-postgresql"
```

### What was changed

Until now Chipster used Bitnami Helm chart and container image to deploy the databases. 

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
* The Bitnami Helm chart was replaced with a StatefulSet. This is placed among other Chipster templates: https://github.com/chipster/chipster-openshift/blob/k3s/k3s/helm/chipster/templates/postgresql-sts.yaml . Until now the database configuration was a bit messy, because there were separate configuration items for the Bitnami chart and Chipster. Now the configuration is simpler, because we can use the our configuration items directly in the StatefulSet.
* The Bitnami image is replaced with the "Docker Official Image" PostgreSQL: https://hub.docker.com/_/postgres . This upstream image is copied to Chipster image repository and tagged like all other Chipster images. This ensures that the image stays available, even if the upstream renames it.
* The Bitnami image always generated configuration files `postgresql.conf` and `pg_hba.conf`. The new image assumes that these files are found from the database volume. The StatefulSet above creates an `initContainer`, which creates these files if necessary.
=======
=======
>>>>>>> e24fd92 (Replace Bitnami chart)
* The Helm chart was replaced with a StatefulSet among other Chipster templates: https://github.com/chipster/chipster-openshift/blob/k3s/k3s/helm/chipster/templates/postgresql-sts.yaml
* The image is replaced with the "Docker Official Image" PostgreSQL: https://hub.docker.com/_/postgres . This upstream image is copied to Chipster image repository and tagged like all other Chipster images.
* The Bitnami image always generated configuration files `postgresql.conf` and `pg_hba.conf`. The new image assumes that these files are found from the database volume. The template above creates an `initContainer`, which creates these files if necessary.

Until now the database configuration was messy, because there were separate configuration items for the Bitnami chart and Chipster. The benefit from this change is, that now the configuration is more simple, when we can use the our configuration items directly in the template.
<<<<<<< HEAD
>>>>>>> e24fd92 (Replace Bitnami chart)
=======
* The Bitnami Helm chart was replaced with a StatefulSet. This is placed among other Chipster templates: https://github.com/chipster/chipster-openshift/blob/k3s/k3s/helm/chipster/templates/postgresql-sts.yaml . Until now the database configuration was a bit messy, because there were separate configuration items for the Bitnami chart and Chipster. Now the configuration is simpler, because we can use the our configuration items directly in the StatefulSet.
* The Bitnami image is replaced with the "Docker Official Image" PostgreSQL: https://hub.docker.com/_/postgres . This upstream image is copied to Chipster image repository and tagged like all other Chipster images. This ensures that the image stays available, even if the upstream renames it.
* The Bitnami image always generated configuration files `postgresql.conf` and `pg_hba.conf`. The new image assumes that these files are found from the database volume. The StatefulSet above creates an `initContainer`, which creates these files if necessary.
>>>>>>> a296af3 (Take backup copy of passwords)
=======
>>>>>>> e24fd92 (Replace Bitnami chart)

