# Change K3s version
## Host path volumes

By default Chipster's Helm templates create Kubernetes volumes (PersistenVolumeClaim, PVC) to store persistent data of databases and file-storage. If you run Chipster on a single node K3s, you may
want to keep the data directly on the `hostPath` volumes. This allows you to uninstall and reinstall K3s and Chipster without losing the data.

NOTE! There is no easy way to revert some of these changes if something goes wrong. Make sure you have working backups before starting!

## Migration, part 1

Take copy of the current passwords:

```bash
kubectl get secret passwords -o yaml > ~/chipster-passwords.yaml
```

Chipster must be uninstalled first, because Kubernetes doesn't allow you to change the volume type of `statefulset`. We can still move the data from the volumes later, because this doesn't delete the volumes. If you haven't yet installed Chipster, you can skip this step.

```bash
helm uninstall chipster
```

## Configure hostPath volumes

Create a directory for each volume:

```bash
pushd /mnt/data
sudo mkdir auth-postgresql session-db-postgresql job-history-postgresql file-storage
sudo chown ubuntu:ubuntu auth-postgresql session-db-postgresql job-history-postgresql file-storage
popd
```

Configure Chipster to store data in these directories. Unfortunately there are to different configuration paths for the database: one for Chipster to create a hostPath volume (e.g. `databases.auth.hostPath`), and another for the database to use that volume (e.g. 'auth-postgresql.persistence.existingClaim`):

```yaml
deployments:
  fileStorage:
    storageHostPath: /mnt/data/file-storage

databases:
  auth:
    hostPath: "/mnt/data/auth-postgresql"
  sessionDb:
    hostPath: "/mnt/data/session-db-postgresql"
  jobHistory:
    hostPath: "/mnt/data/job-history-postgresql"

auth-postgresql:
  persistence:
    existingClaim: "auth-pvc-volume-postgres"

session-db-postgresql:
  persistence:
    existingClaim: "session-db-pvc-volume-postgres"

job-history-postgresql:
  persistence:
    existingClaim: "job-history-pvc-volume-postgres"
```

Deploy the new configuration and wait until the old pods have disappeared:

```bash
bash deploy.bash -f ~/values.yaml
watch kubectl get pod
```

## Migration, part 2

We have to move the old data from the old volume directories in `/mnt/data/k3s/storage/` to the new hostPath directories in `/mnt/data`.
Unfortunately each old volume directory has an unieque VOLUME_ID in its name. Check the directory names and adjust the `mv` commands accordingly:

```bash
pushd /mnt/data

sudo ls -alh k3s/storage/

sudo mv k3s/storage/pvc-VOLUME_ID_default_storage-file-storage-0/* file-storage
sudo mv k3s/storage/pvc-VOLUME_ID_default_data-chipster-job-history-postgresql-0/* job-history-postgresql
sudo mv k3s/storage/pvc-VOLUME_ID_default_data-chipster-session-db-postgresql-0/* session-db-postgresql
sudo mv k3s/storage/pvc-VOLUME_ID_default_data-chipster-auth-postgresql-0/* auth-postgresql
popd
```

Restart statefulsets (sts, databases and file-storage) and other Chipster deployments. Wait until old pods have disappeared.

```bash
kubectl rollout restart sts
bash restart.bash
watch kubectl get pod
```

Open Chipster and verify that you can see and open the old sessions.

Maybe it would be a good idea to remove the old unused volumes. Make sure once more that folders in `/mnt/data/k3s/storage/` are empty and then delete those:

```bash
# WARNING: this will remove your data volumes
kubectl delete pvc data-chipster-auth-postgresql-0
kubectl delete pvc data-chipster-session-db-postgresql-0
kubectl delete pvc data-chipster-job-history-postgresql-0
kubectl delete pvc storage-file-storage-0
```

## Reinstall K3s

If you have done all the previous steps on this page, you can uninstall K3s:

```bash
/usr/local/bin/k3s-uninstall.sh
```

Restore the old passwords:

```bash
kubectl apply -f ~/chipster-passwords.yaml
```

Install K3s: TODO how to install different versions?

```bash
curl -sfL https://get.k3s.io | sh -
```

Deploy Chipster (assuming you have settings in `~/values.yaml`):

```bash
bash deploy.bash -f ~/values.yaml
```