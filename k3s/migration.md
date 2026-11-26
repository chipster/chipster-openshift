# Chipster in K3s Migration

Some Chipster versions need extra steps when you update an existing server. The chapters below are
in version order. Before updating, read the chapters of all versions that are newer than your
current version, up to the version you are updating to.

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

## Update to v4.12.0 (PostgreSQL 14)

The Chipster versions up to v4.11.1 used PostgreSQL 11, and PostgreSQL 14 is used since v4.12.0.
Before updating from v4.11.1 or older, [update the PostgreSQL and migrate the data](https://github.com/chipster/chipster-openshift/blob/v4.19.5/k3s/update-postgres.md).

## Update to v4.15.0 (K3s v1.32.4 and Ubuntu 24.04)

The Chipster versions up to v4.14.2 used K3s v1.26.4 and Ubuntu 20.04. Since v4.15.0, K3s v1.32.4
and Ubuntu 24.04 are used. Follow the [K3s instructions](#k3s-v1324) **before** updating to
v4.15.0. You can update [Ubuntu](#ubuntu-2404) before or after updating Chipster.

### K3s v1.32.4

Since Chipster version v4.15.0, the Ansible playbook in the update instructions will update the K3s from version `v1.26.4` to `v1.32.4`. The new K3s will have different API version for the IngressRoute object. After K3s has been updated, Helm and kubectl cannot manage the old IngressRoute objects anymore.

Uninstall Chipster before the K3s update to prevent problems later:

```bash
helm uninstall chipster
```

This didn't delete the data on our test servers, but take the necessary precautions condsidering backups.

And then continue with the [Chipster update instructions](README.md#Updates).

#### Recovering from Failed K3s v1.32.4 Update

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

### Ubuntu 24.04

The table of different Chipster versions and corresponding Ubuntu and K3s versions:

| Chipster version  | Ubuntu on K3s host | Ubuntu in Chipster containers (except comp) | Ubuntu in comp containers | K3s version |
| ----------------- | ------------------ | ------------------------------------------- | ------------------------- | ----------- |
| <= v4.13.15       | 20.04              | 20.04                                       | 16.04 or 20.04            | v1.26.4     |
| v4.14.0 - v4.14.2 | 20.04              | 24.04                                       | 16.04, 20.04 or 24.04     | v1.26.4     |
| >= v4.15.0        | 24.04              | 24.04                                       | 16.04, 20.04 or 24.04     | v1.32.4     |

Until Chipster version v4.13.15, the Chipster containers (except comp) were running Ubuntu 20.04. If you installed any version between v4.14.0 and v4.14.2, those containers were running Ubuntu 24.04, but the K3s host was still running older Ubuntu 20.04. We have now updated the [Chipster installation instructions](README.md) in Chipster version v4.15.0. Those now start also from Ubuntu 24.04 on the K3s host. If you are running a Chipster version v4.14.2 or older, you should update K3s (see the previous section) and Ubuntu on the K3s host. The next two sections show you two options for doing it.

Analysis tools in `comp` containers run in Ubuntu 16.04, Ubuntu 20.04 or Ubuntu 24.04. That shouldn’t pose significant security risks, because comp is well protected behind other Chipster services.

When a job is started, the comp gets an access token only for the session where it's run. The most important attack vectors for the comp are the input files and parameters, but the user who can change the parameters and input files, can already access all the data in the session anyway.

#### Option 1: Install New Server (recommended)

Our recommended option is to install a new server and make sure that all necessary data is moved before removing the old server. The tools-bin package wasn’t updated at this point, so you can reuse your possible local copies of the latest tools-bin package (tools-bin version chipster-4.9.0).

The sessions from the old server can be moved either by following the [backup instructions](backup.md) or users can do it themselves by downloading the sessions to zip files from the old server and upload those to the new server.

#### Option 2: Update Existing Server

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

## Update to v4.18.0 (replace Bitnami image)

Chipster has used Bitnami image to run its PostgreSQL databases until version v4.17.5. Unfortunately Bitnami has decided to stop providing this image after September 29th: https://hub.docker.com/r/bitnami/postgresql .

This is fixed in Chipster version v4.18.0. Do the following steps to update. This shouldn’t delete your sessions, but normal backup precautions are of course recommended when making changes to databases.

1. Take a backup copy of the passwords Secret

```bash
kubectl get secret passwords -o json > ~/passwords-backup.json
```

2. Delete old Bitnami chart (otherwise Helm will deploy it with default name `chipster-postgresql`):

```bash
rm helm/chipster/charts/postgresql-16.0.1.tgz
```

3. Delete Services of old databases:

```bash
kubectl delete service/chipster-auth-postgresql service/chipster-job-history-postgresql service/chipster-session-db-postgresql
```

4. Delete StatefulSets of old databases:

```bash
kubectl delete sts/chipster-auth-postgresql sts/chipster-job-history-postgresql sts/chipster-session-db-postgresql
```

5. (Optional) If you have used hostPath volumes for your databases like shown in https://github.com/chipster/chipster-openshift/blob/k3s/k3s/change-k3s-version.md#configure-hostpath-volumes , the new configuration is much simpler. If you have the following in your ~/values.yaml, it can be removed:

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

6. After this, follow the usual instructions in https://github.com/chipster/chipster-openshift/blob/k3s/k3s/README.md#updates to update to version v4.18.0. When running “bash generate-passwords.bash”, you will see little bit of extra text telling that the three database passwords are migrated to their new names.

7. When you have completed the update and you can still open your old sessions in Chipster, you can delete the backup copy of the passwords Secret:

```bash
rm ~/passwords-backup.json
```

### Troubleshooting

If you see an error like this, see steps 3 and 4.

```
Error: UPGRADE FAILED: cannot patch "chipster-auth-postgresql" with kind Service: Service "chipster-auth-postgresql"
```

### What was changed

Until now Chipster used Bitnami Helm chart and container image to deploy the databases.

- The Bitnami Helm chart was replaced with a StatefulSet. This is placed among other Chipster templates: https://github.com/chipster/chipster-openshift/blob/k3s/k3s/helm/chipster/templates/postgresql-sts.yaml . Until now the database configuration was a bit messy, because there were separate configuration items for the Bitnami chart and Chipster. Now the configuration is simpler, because we can use the our configuration items directly in the StatefulSet.
- The Bitnami image is replaced with the "Docker Official Image" PostgreSQL: https://hub.docker.com/_/postgres . This upstream image is copied to Chipster image repository and tagged like all other Chipster images. This ensures that the image stays available, even if the upstream renames it.
- The Bitnami image always generated configuration files `postgresql.conf` and `pg_hba.conf`. The new image assumes that these files are found from the database volume. The StatefulSet above creates an `initContainer`, which creates these files if necessary.

## Update to v4.20.1 (PostgreSQL 17)

The Chipster versions up to v4.19.5 used PostgreSQL 14, and PostgreSQL 17 is used since v4.20.1.
To update to v4.20.1, follow the [PostgreSQL migration instructions](update-postgres.md) instead of
the usual update instructions.

## Update to v4.21.0

The `bash-job-scheduler` ServiceAccount was bound to the built-in `edit` ClusterRole, which granted far more than the scheduler needs (read access to all Secrets, `pods/exec` into any pod, etc.). Since v4.21.0 it is bound to a minimal namespaced `Role` (`scheduler-role.yaml`) instead (GHSA-3j6x-m3jw-r5mg).

A RoleBinding's `roleRef` is immutable, so an in-place `helm upgrade` cannot change the existing binding and fails with:

```
Error: UPGRADE FAILED: cannot patch "bash-job-scheduler-rb" with kind RoleBinding:
RoleBinding.rbac.authorization.k8s.io "bash-job-scheduler-rb" is invalid:
roleRef: ...: cannot change roleRef
```

`deploy.bash` removes the old binding automatically before upgrading. If you run `helm upgrade` by hand, delete it first:

```bash
kubectl delete rolebinding bash-job-scheduler-rb
bash deploy.bash -f ~/values.yaml
```

This is a one-time step; fresh installs are unaffected.

## Update to v4.21.5

### Comp job NetworkPolicy

Comp jobs process untrusted input files and parameters, so a NetworkPolicy now limits their connections to DNS, the Chipster services they need and the internet. Private networks and the cloud metadata service are blocked.

If your jobs use an http proxy in a private network, allow it as shown in [Chipster behind proxy](behind-proxy.md). Otherwise the jobs can't access the internet after the update. Other hosts in private networks can be allowed in the same way, see `compJobNetworkPolicy` in [values.yaml](helm/chipster/values.yaml).

## Update to v4.22.0

### Database texts from large objects to text columns

Until now the long texts in the databases (job screen outputs, session and dataset notes etc.) were
stored as PostgreSQL large objects. Since v4.22.0 they are stored in ordinary text columns, which
makes session-db much faster, especially when listing the jobs of a session. The services convert
the data automatically when the new version starts for the first time:

- session-db: the notes of sessions and datasets, and the screen output, source code, state
  details and tool description of jobs
- job-history: the screen output of jobs
- auth: the codes of OIDC logins

On most servers this takes only a moment and you can update as usual. Check the free disk space
first. If the conversion takes too long or fails, see
[Troubleshooting the conversion](#troubleshooting-the-conversion).

If you have a large installation, consider practising the update on a copy of the databases
first, to see how long the conversion takes, and read the troubleshooting chapter beforehand.

Things to know before you start:
- The services are not available until the conversion has finished. If it fails or is
  interrupted, the database is left as it was and the conversion starts again when the service
  restarts.
- **You can't go back to an older Chipster version afterwards** without restoring the databases
  from a backup taken before the update. Take [backups](backup.md) first.
- The commands below are run on the K3s host in the `k3s` directory. Single quotes (`'`) are
  important, so that your shell doesn't expand the variables, which are only defined in the
  database container.

#### 1. Check the free disk space

The conversion writes the texts again, so make sure that the disk of each database has free space
of at least the size of the database plus 1 GB for the transaction log.

#### 2. Update

Follow the usual [update instructions](README.md#updates). Then check that `session-db`,
`job-history` and `auth` start:

```bash
kubectl get pod
```

If one of them keeps restarting, see
[Troubleshooting the conversion](#troubleshooting-the-conversion).

#### 3. Release the disk space

The conversion leaves the old large objects on the disk. Remove them and give the space back to
the operating system. Chipster can be used meanwhile.

```bash
for db in auth session-db job-history; do
  kubectl exec statefulset/chipster-$db-postgresql -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD vacuumlo -U postgres -l 1000 $POSTGRES_DB'
  kubectl exec statefulset/chipster-$db-postgresql -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres $POSTGRES_DB -c "VACUUM FULL pg_largeobject"'
done
```

If you use Chipster's [built-in backup](backup-to-s3.md), it runs `vacuumlo` before each backup,
so the first backup after the update takes longer, unless you have done this step already.

#### Troubleshooting the conversion

##### A service keeps restarting

If `session-db`, `job-history` or `auth` keeps restarting (its `RESTARTS` count grows) and its
log ends with a Flyway message about migrating to `Convert oid columns to text`, the conversion
takes longer than the liveness probe allows. The services start to answer the probe only after
the conversion, and Kubernetes restarts a service that doesn't answer for about a minute. Nothing
is lost, because each interrupted conversion is rolled back, but it never finishes. If the log
shows an error instead, see [The conversion fails](#the-conversion-fails). See the log of the
previous restart for example with:

```bash
kubectl logs deployment/session-db --previous | grep -E 'Migrating|ERROR:'
```

In that case, restart the database pod of that service, because the database may still be
running the interrupted conversion, and deploy again with a longer probe period (in seconds):

```bash
kubectl delete pod chipster-session-db-postgresql-0
bash deploy.bash -f ~/values.yaml --set deploymentDefault.livenessProbe.periodSeconds=3600
kubectl logs deployment/session-db -f
```

When the conversion has finished and the services are running, deploy again without the `--set`
argument, to set the probe back to normal:

```bash
bash deploy.bash -f ~/values.yaml
```

##### The conversion fails

The conversion stops, and the service doesn't start, if a text contains a NUL character or
isn't valid UTF-8. Normally this doesn't happen. If it does, the log of the service shows
an error like `invalid byte sequence for encoding "UTF8"`, and the database is left as it was.
This lists the texts that can't be converted. It reads all the old texts, so on a large database
it takes a while:

```bash
cat > lo-bad.sql <<'EOF'
create function pg_temp.lo_bad(o oid) returns boolean language plpgsql as $$
begin
  if o is null or not exists (select 1 from pg_largeobject_metadata where oid = o) then
    return false;
  end if;
  perform convert_from(lo_get(o), 'UTF8');
  return false;
exception when character_not_in_repertoire or untranslatable_character then
  return true;
end
$$;
EOF

check() {
  kubectl exec -i statefulset/chipster-$1-postgresql -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres -v ON_ERROR_STOP=1 $POSTGRES_DB'
}

(cat lo-bad.sql; echo "
select 'session' as type, sessionid as id from session where pg_temp.lo_bad(notes)
union all select 'dataset', datasetid from dataset where pg_temp.lo_bad(notes)
union all select 'job', jobid from job where pg_temp.lo_bad(screenoutput) or pg_temp.lo_bad(sourcecode)
  or pg_temp.lo_bad(statedetail) or pg_temp.lo_bad(tooldescription);") | check session-db

(cat lo-bad.sql; echo "select jobid from jobhistory where pg_temp.lo_bad(screenoutput);") | check job-history

(cat lo-bad.sql; echo "select count(*) from oidcloginsession where pg_temp.lo_bad(code);") | check auth
```

Please let us know about the problem on the chipster-tech list. Until it has been solved, you can
go back to the previous Chipster version, because the database wasn't changed.
