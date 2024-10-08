# Update PostgreSQL 11 to 14

## Introduction

Chipster has three PostgreSQL databases `auth`, `job-history` and `session-db`. Major releases of PostgreSQL change its internal storage format. These instructions show how to dump and restore the contents of the databases to move data to a new major version.

Let's start by checking the currrent version. All Chipster installations made before 2024-10-08 should be using PostgreSQL 11:

```bash
$ kubectl exec -it chipster-session-db-postgresql-0 -- psql --version
Defaulted container "chipster-session-db-postgresql" out of: chipster-session-db-postgresql, init-chmod-data (init)
psql (PostgreSQL) 11.6
```

## Dump databases

Dump old databases to sql files. In this exmample the files are saved in the home directory. Use other location if you need more storage space.

```bash
kubectl exec -i chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres auth_db' > ~/auth.sql
kubectl exec -i chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres job_history_db' > ~/job-history.sql
kubectl exec -i chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres session_db_db' > ~/session-db.sql
```

## Install new PostgreSQL

TODO replace "git switch" with "git pull" after the branch has been merged

Download the new PostgreSQL Helm Chart and deploy it. The command `helm uninstall chipster` doesn't delete volumes, so the users' files on file-storage service are safe. Deploy Chipster with the new version and wait until all pods are running again.

```bash
git switch postgres14
helm dependencies update helm/chipster
helm uninstall chipster
bash generate-passwords.bash
bash deploy.bash -f ~/values.yaml
watch kubectl get pod
```

Check that the PostgreSQL version is now 14:

```bash
$ kubectl exec -it chipster-session-db-postgresql-0 -- psql --version
psql (PostgreSQL) 14.7
```

## Restore the database dumps

The new database is configured to store data in directory `/bitnami/postgresql/data_14` instead of the old `/bitnami/postgresql/data`. If you open Chipster now, it doesn't show any sessions.

Let's restore the database dumps, assuming that you saved the .sql files in the home directory. This will drop the database tables in the new databases, but that shouldn't matter, because the new databases should still be empty after those were just created.

```bash
cat ~/auth.sql | kubectl exec -i chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres auth_db'
cat ~/job-history.sql | kubectl exec -i chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres job_history_db'
cat ~/session-db.sql | kubectl exec -i chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres session_db_db'
```

## Clean-up

Make sure all databases are now using the new diretory `data_14` and not the old `data`. Do not continue if this is not the case!

```bash
kubectl exec -it chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres auth_db -c "show data_directory"'
kubectl exec -it chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres job_history_db -c "show data_directory"'
kubectl exec -it chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres session_db_db -c "show data_directory"'
```

Check also that you can see again the sessions in Chipster, open them and see the contents of the files. If all is fine, you can remove the old database directories:

```bash
kubectl exec -it chipster-auth-postgresql-0 -- rm -rf /bitnami/postgresql/data
kubectl exec -it chipster-job-history-postgresql-0 -- rm -rf /bitnami/postgresql/data
kubectl exec -it chipster-session-db-postgresql-0 -- rm -rf /bitnami/postgresql/data
```

You can also remove the database dumps:

```bash
rm ~/auth.sql
rm ~/job-history.sql
rm ~/session-db.sql
```

## Recovering from accidental update

If you tried to update Chipster from version v4.11.1 (or older) to v4.12.0 (or newer) without following instructions on this apge first, your Chipster won't start. If you check the output of command `kubectl get pod`, you will notice that instead of three database pods `chipster-auth-postgresql-0`, `chipster-session-db-postgresql-0` and `chipster-job-history-postgresql-0`, you only have one, called `chipster-postgresql-0`. This is because your old PostgreSQL Helm template doesn't understand the new configuration option names. In this case, get old deployment scripts:

```bash
git checkout v4.11.1
bash deploy.bash -f ~/values.yaml
kubectl delete pod file-storage-0
bash restart.bash
watch kubectl get pod
```

When all pods are running again, follow this page from the start to update the databases. Then go back to latest deployment scripts:

```bash
git checkout master
```

After that you can finally update Chipster safely.
