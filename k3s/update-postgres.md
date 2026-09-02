# Update PostgreSQL 14 to 17

## Introduction

Chipster has three PostgreSQL databases `auth`, `job-history` and `session-db`. Major releases of PostgreSQL change its internal storage format. These instructions show how to dump and restore the contents of the databases to move data to a new major version.

Let's start by checking the currrent version. Chipster installations since v4.18.0 and until version v4.19.5 should be using PostgreSQL 14.

```bash
$ kubectl exec -it chipster-session-db-postgresql-0 -- psql --version
psql (PostgreSQL) 14.23 (Debian 14.23-1.pgdg13+1)
```

## Dump databases

Dump old databases to sql files. In this exmample the files are saved in the home directory. Use other location if you need more storage space.

```bash
kubectl exec -i chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres auth_db' > ~/auth.sql
kubectl exec -i chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres job_history_db' > ~/job-history.sql
kubectl exec -i chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres session_db_db' > ~/session-db.sql
```

## Install new PostgreSQL

PostgreSQL's data directory and container image are baked into the StatefulSet spec, and Kubernetes won't let an existing StatefulSet's `volumeClaimTemplates` be changed in place by the `helm upgrade` that `deploy.bash` normally does. Delete the three PostgreSQL StatefulSets — this leaves their PersistentVolumes alone, so the old PostgreSQL 14 data stays intact on disk:

```bash
kubectl delete statefulset chipster-auth-postgresql
kubectl delete statefulset chipster-job-history-postgresql
kubectl delete statefulset chipster-session-db-postgresql
```

The PostgreSQL 17 databases will be temporarily empty until you restore the dumps below. **Once the update is done, come back to this page** to continue with restoring the database dumps.

Now [update Chipster](README.md#update-chipster-to-selected-version) to `v4.20.1` or later, following the normal update instructions — its `deploy.bash` step will recreate just the three deleted StatefulSets, and upgrade everything else normally.

After the update, check that the PostgreSQL version is now 17:

```bash
$ kubectl exec -it chipster-session-db-postgresql-0 -- psql --version
psql (PostgreSQL) 17.11
```

## Restore the database dumps

The new database is configured to store data in directory `/var/lib/postgresql/data_17` instead of the old `/var/lib/postgresql/data_14`. If you open Chipster now, it doesn't show any sessions.

Let's restore the database dumps, assuming that you saved the .sql files in the home directory. This will drop the database tables in the new databases, but that shouldn't matter, because the new databases should still be empty after those were just created.

On large/long transfers `kubectl` (v1.32.4) can drop connection by itself — WebSocket exec transport loses its ping keepalive under sustained stdin writes. If that happens mid-transfer, PostgreSQL rolls back all large-object content in the database, silently leaving every large object empty. Set `KUBECTL_REMOTE_COMMAND_WEBSOCKETS=false` first to make `kubectl` fall back to the older, unaffected SPDY transport for the restore:

```bash
export KUBECTL_REMOTE_COMMAND_WEBSOCKETS=false

cat ~/auth.sql | kubectl exec -i chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres auth_db'
cat ~/job-history.sql | kubectl exec -i chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres job_history_db'
cat ~/session-db.sql | kubectl exec -i chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres session_db_db'
```

## Clean-up

Make sure all databases are now using the new diretory `data_17` and not the old `data_14`. Do not continue if this is not the case!

```bash
kubectl exec -it chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres auth_db -c "show data_directory"'
kubectl exec -it chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres job_history_db -c "show data_directory"'
kubectl exec -it chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres session_db_db -c "show data_directory"'
```

Check also that you can see again the sessions in Chipster, open them and see the contents of the files. If all is fine, you can remove the old database directories:

```bash
kubectl exec -it chipster-auth-postgresql-0 -- rm -rf /var/lib/postgresql/data_14
kubectl exec -it chipster-job-history-postgresql-0 -- rm -rf /var/lib/postgresql/data_14
kubectl exec -it chipster-session-db-postgresql-0 -- rm -rf /var/lib/postgresql/data_14
```

You can also remove the database dumps:

```bash
rm ~/auth.sql
rm ~/job-history.sql
rm ~/session-db.sql
```
