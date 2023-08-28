# Change K3s version
## Host path volumes

By default Chipster's storage volumes (PersistenVolumeClaim, PVC) are managed by the K3s. If you uninstalled and reinstalled K3s, the new installation would not find the data on your old volumes. When running Chipster on a single node K3s, you may
want to keep the data directly on the `hostPath` volumes instead. Then the data is stored in plain directories on the host. This allows you to uninstall and reinstall K3s and Chipster without losing the data.

NOTE! There is no easy way to revert some of these changes if something goes wrong. Make sure you have working backups before starting!

## Prepare for migration

If you haven't yet installed Chipster, you can skip this step.

Take copy of the current passwords. We will need the database passwords when we later want to connect to current databases.

```bash
kubectl get secret passwords -o yaml > ~/chipster-passwords.yaml
```

Chipster must be uninstalled first, because Kubernetes doesn't allow you to change the volume type of `statefulset`. We can still move the data from the volumes later, because this doesn't delete the volumes. 

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

Configure Chipster to store data in these directories. Add the following configuration to your `~/values.yaml`. Unfortunately there are to separate configuration sections for each database: one for Chipster to create a hostPath volume (e.g. `databases.auth.hostPath`), and another for the database itself to use that volume (e.g. 'auth-postgresql.persistence.existingClaim`):

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

## Migrate data

We have to move the data from the old volume directories in `/mnt/data/k3s/storage/` to the new hostPath directories in `/mnt/data`.
Unfortunately each old volume directory has an unieque VOLUME_ID in its name. Check the directory names and adjust the `mv` commands accordingly:

```bash
pushd /mnt/data

sudo ls -lah k3s/storage/

# replace the VOLUME_IDs and remember to include the asterisk '*' in the end!
sudo mv k3s/storage/pvc-VOLUME_ID_default_storage-file-storage-0/* file-storage
sudo mv k3s/storage/pvc-VOLUME_ID_default_data-chipster-job-history-postgresql-0/* job-history-postgresql
sudo mv k3s/storage/pvc-VOLUME_ID_default_data-chipster-session-db-postgresql-0/* session-db-postgresql
sudo mv k3s/storage/pvc-VOLUME_ID_default_data-chipster-auth-postgresql-0/* auth-postgresql
popd
```

Deploy the new configuration and wait until the all pods have started:

```bash
bash deploy.bash -f ~/values.yaml
watch kubectl get pod
```

Open Chipster and verify that you can see and open the old sessions.

It would probably be a good idea to remove the old unused volumes for the sake of clarity. Make sure once again that all folders in `/mnt/data/k3s/storage/` are empty and then delete the volumes:

```bash
# WARNING: this will remove your data volumes, make sure you have moved your data!
kubectl delete pvc data-chipster-auth-postgresql-0
kubectl delete pvc data-chipster-session-db-postgresql-0
kubectl delete pvc data-chipster-job-history-postgresql-0
kubectl delete pvc storage-file-storage-0
```

## Reinstall K3s

Now your data is stored on the host directories and you have a copy of your database passwords. You can uninstall K3s:

```bash
/usr/local/bin/k3s-uninstall.sh
```

Install the K3s version you want. The default version is defined in the [Ansible playbook](https://github.com/chipster/chipster-openshift/blob/k3s/k3s/ansible/install-deps.yml). For example:

```bash
ansible-playbook ansible/install-deps.yml -i "localhost," -c local -e user=$(whoami) -e k3s_version=v1.26.3+k3s1
```

Restore the old passwords:

```bash
kubectl apply -f ~/chipster-passwords.yaml
```

Deploy Chipster and wait until the all pods have started (assuming you have your configuration in `~/values.yaml`):

```bash
bash deploy.bash -f ~/values.yaml
watch kubectl get pod
```