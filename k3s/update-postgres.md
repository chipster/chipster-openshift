# Update PostgreSQL
## Introduction



## Dump databases

Dump old databases to sql files. In this exmample the files are saved in the home directory. Use other location if you need more storage space.

```bash
kubectl exec -it chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres session_db_db' > ~/session-db.sql
kubectl exec -it chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres auth_db' > ~/auth.sql
kubectl exec -it chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres job_history_db' > ~/job-history.sql
```

## Install new PostgreSQL

TODO update branch or values.yaml

Download the new PostgreSQL Helm Chart and deploy it. The command `helm uninstall chipster` doesn't delete volumes, so the users' files on file-storage service are safe. Deploy Chipster with the new version and wait until all pods are running again.

```bash
helm dependencies update helm/chipster
helm uninstall chipster
bash deploy.bash -f ~/values.yaml 
watch kubectl get pod
```

## Restore the database dumps

The new database is configured to store data in directory `/bitnami/postgresql/data_14` instead of the old `/bitnami/postgresql/data`. If you open Chipster now, it doesn't show any sessions. Let's restore the database dumps.

This assumes that you saved the .sql files in the home directory.

```bash
cat ~/session-db.sql | kubectl exec -it chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres session_db_db'
cat ~/auth.sql | kubectl exec -it chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres auth_db'
cat ~/job-history.sql | kubectl exec -it chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres job_history_db'
```

## Clean-up

Make sure all databases are now using the new diretory `data_14` and not the old `data`. Do not continue if this is not the case!

```bash
kubectl exec -it chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres session_db_db -c "show data_directory"'
kubectl exec -it chipster-auth-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres auth_db -c "show data_directory"'
kubectl exec -it chipster-job-history-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres job_history_db -c "show data_directory"'
```

Check also that you can see again the sessions in Chipster, open them and see the contents of the files. If all is fine, you can remove the old database directories:

```bash
kubectl exec -it chipster-session-db-postgresql-0 -- rm -rf /bitnami/postgresql/data
kubectl exec -it chipster-auth-postgresql-0 -- rm -rf /bitnami/postgresql/data
kubectl exec -it chipster-job-history-postgresql-0 -- rm -rf /bitnami/postgresql/data
```

You can also remove the database dumps:

```bash
rm ~/session-db.sql
rm ~/auth.sql
rm ~/job-history.sql
```