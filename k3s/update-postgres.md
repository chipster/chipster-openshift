# Update PostgreSQL 11 to 14
## Introduction

Chipster has three PostgreSQL databases `auth`, `job-history` and `session-db`. Major releases of PostgreSQL change its internal storage format. These instructions show how to dump and restore the contents of the databases to move data to a new major version.

Let's start by checking the currrent version. All Chipster installations made before TODO 2023-05-XX should be using PostgreSQL 11:

```bash
$ kubectl exec -it chipster-session-db-postgresql-0 -- psql --version
Defaulted container "chipster-session-db-postgresql" out of: chipster-session-db-postgresql, init-chmod-data (init)
psql (PostgreSQL) 11.6
```

## Dump databases

Dump old databases to sql files. In this exmample the files are saved in the home directory. Use other location if you need more storage space.

```bash
kubectl exec -it chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres auth_db' > ~/auth.sql
kubectl exec -it chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres job_history_db' > ~/job-history.sql
kubectl exec -it chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres session_db_db' > ~/session-db.sql
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

Let's restore the database dumps, assuming that you saved the .sql files in the home directory.

```bash
cat ~/auth.sql | kubectl exec -it chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres auth_db'
cat ~/job-history.sql | kubectl exec -it chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres job_history_db'
cat ~/session-db.sql | kubectl exec -it chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres session_db_db'
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