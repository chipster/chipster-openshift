# Backup Chipster with a kubectl command
## Dump databases with kubectl

The examples here show only how to backup the `session-db` database. To do the same for two other databases, simply replace all instances of text `session-db` with `auth` or `job-history` in these examples. While doing this, stick to the same naming convention in the examples. So if the text in the example uses underscore `_` instead of dash `-`, then use that also the new value, like `job_history`.

The PostgreSQL database doesn't remove automatically orphaned large objects. It's advisable to run PostgreSQL's command `vacuumlo` to remove those before taking backups. On an actively used (or tested) server this can reduce the backup size and restore time significantly.

One complication is that the database resides in a container. We'll use `kubectl exec` command to run commands in that container. We do have the database password available in a environment variable `$POSTGRES_PASSWORD` inside the container. Unfortunately PostgreSQL tools try to find it with a bit different name `PGPASSWORD`. We'll run a new instance of `bash` to set the password to this another variable name before running the actual commnad:

```bash
kubectl exec -it chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD vacuumlo -U postgres session_db_db'
```

Save a database dump to a file on the virtual machine:

```bash
kubectl exec -it chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump --clean -U postgres session_db_db' > session-db.sql
```

Finally, store this file (in addition to two other files from `auth` and `job-history` databases) to your external backup system.

## Copy file-storage files with kubectl

You should take a copy of all files in file-storage. Check the total size:

```bash
kubectl exec file-storage-0 -- du -sh storage
```

Copy the files. Set the BACKUP_DIR to some place on the Chispter virtual machien that has enough free space. This command makes it simple to copy small amount of files. If you have more files, you may want to use the next command instead.

```bash
kubectl cp file-storage-0:storage BACKUP_DIR/storage
```

For large transfer you probably want to copy the files with this longer command which shows you some progress information:

```bash
sudo apt install pv
mkdir BACKUP_DIR
kubectl exec -i file-storage-0 -- tar cf - storage | pv | tar xf - -C BACKUP_DIR
```

Then store the BACKUP_DIR to your external backup system.
