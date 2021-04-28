# Chipster server backups
## Backup considerations

Things to consider when designin a backup system
- How often to take backups? Longer the interval, more data will be lost in when the backups are needed
- How many copies? One backup copy may be enough to restore the server after an admin accidentally removes something. On the other hand, protection against bugs that corrupt data silently could require backups of several months or even years
- How much resources to devote for the backup system?
- Backups are useful only if they survive the accident that destroyed the primary data. On the other hand, more separation usually makes the backup copies harder to do. How much separation is needed: different volume, different server, different data center or different admin?
- Practice. The only way to know whether backups really work is to try out your restore process regularly to check that you actually can restore the server from the backups

## Backup deployment configuration

Take a copy of your `~/values.yaml`. That should be enough for setting up the system itself again. If you have made any other customizations to your server, copy those too.

## Backup databases and file-storage files

In addition to settting up the system again, you want to be able to restore the users' data. For this you need backups of the databases and the actual data from the file-storage files.

## Do backups with kubectl command or with built-in backup feature

Here are instructions for two different ways to make backups of the Chipster server. You can either copy the data using a [kubectl commands](backup-to-file.md) or with Chipster's [built-in backup feature](backup-to-s3.md). 

Copying the backup data with kubectl commands is simple to understand and easy to customize to your specific needs. Storing backups on the same virtual machine server usually isn't safe enough, but makes it easy for you to move those files forward to whatever backup system you happen to have.

Chipster's built-in backup feature can compress, encrypt and upload the backup data to a S3 compatible object storage and store incremental copies on another remote archive server. Please see its instructions to evaluate whether it's suitable in your environment. 

You don't have to pick just one system. For example, you can use the kubectl command to backup databases which usually are relatively small and still use the built-in backup feature for the file-storage files.

## Which databases to backup

There are three PostgreSQL databases in Chipster: `session-db`, `auth` and `job-history`. 

You must have backup of the session-db database to be able to restore users' analysis sessions (in addition to the file-storage files, of course). 

The other two databases aren't that critical. The auth database contains users’ names and email addresses and possibly the timestamp when he or she accepted the terms of use (if you have managed to configure this without instructions). You will get the name and email again when the user logs in next time, so it’s not that critical if you lose this database. The job history database is for generating statistics about the number of jobs and consumed resources.

## Restore
### How to delete a database

Here is the procedure for deleting everything in the database, for example when rehearsing the restore process on a test server.

Shut down the database pod:

```bash
kubectl scale --replicas 0 sts/chipster-session-db-postgresql
```

Delete the database volume:

```bash
kubectl delete pvc data-chipster-session-db-postgresql-0
```

Start the pod and create the database volume again:

```bash
bash deploy.bash -f ~/values.yaml
```

### Restore database dump

Copy the `.sql` file from your backup system back to the Chipster virtual machine. Restore it (which will also remove all current data in the database):

```bash
cat session-db.sql | kubectl exec -it chipster-session-db-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres session_db_db'
```


### Delete file-storage files

```bash
kubectl exec file-storage-0 -- bash -c 'rm -rf storage/*'
```

### Restore file-storage files

Simple command:

```bash
kubectl cp BACKUP_DIR/storage file-storage-0:.
```

Or a longer command with progress information:

```bash
tar cf - -C BACKUP_DIR storage | pv | kubectl exec -i file-storage-0 -- tar xf - --no-overwrite-dir
```

