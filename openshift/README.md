# chipster-openshift

Bash scripts and Dockerfiles for building and deploying Chipster's Rest API backend on OpenShift Origin.

## Maintenance
### Restore backup
#### Sequential

Let's assume we are restoring the sesssion-db backup.

* Scale down session-db and backup deployments to 0
 * Remove the old database. Use session-db-postgres pod Terminal to run `dropdb session_db_db`.  If postgres (and thus the pod) refuses to start, use the debug terminal and remove the postgres data folder)
 
```bash
dropdb session_db_db
```

* Create a new database in the terminal of the session-db-postgres pod

```bash
createdb session_db_db
psql session_db_db
alter system set synchronous_commit to off;
# press Ctrl+D to quit psql
pg_ctl reload -D /var/lib/pgsql/data/userdata
```

* Scale the backup deployment to 1. Run on you laptop

```bash
oc rsh dc/backup
export PGPASSWORD="$(cat /opt/chipster-web-server/conf/chipster.yaml | grep db-pass-session-db | cut -d " " -f 2)"
PGURL="$(cat /opt/chipster-web-server/conf/chipster.yaml | grep db-url-session-db | cut -d " " -f 2 | sed s/jdbc://)"
pushd db-backups
BACKUP_FILE=""

# check the uncompressed file size
cat $BACKUP_FILE | lz4 -d | pv > /dev/null
cat $BACKUP_FILE | lz4 -d | pv | psql --dbname $PGURL --username user > ../logs/session-db-restore.log
```
   
#### Parallel

Running `psql` to restore a sql dump processes the dump file about 70 kB/s when it's creating large objects and 800 kB/s when it's creating blobs. With that speed it takes several hours to restore a database of few gigabytes. `pg_restore` would support parallel restore, but it works only for custom and directory formats, whereas we have a sql dump. 

It's seems to be possible to speed this up by splitting the dump and creating large objects and blobs in parallel. At the moment this produced log  warnings of files extending beyond their eof mark, let's try again later when the postgres data is not stored on GlusterFS.         

```bash
# calculate row numbers of each section

lo_start="$(cat all.sql | grep "SELECT pg_catalog.lo_create" -n | head -n 1 | cut -d ":" -f 1)"
table_start="$(cat all.sql | grep "Data for Name: " -n | head -n 1 | cut -d ":" -f 1)"
blobs_start="$(cat all.sql | grep "Data for Name: BLOBS" -n | cut -d ":" -f 1)"
commit_end="$(cat all.sql | grep "COMMIT;" -n | cut -d ":" -f 1)"
eof="$(cat all.sql | wc -l)"

# split the file sections to separate files
# these numbers happened to work for one file, calculate more specific row numbers above if necessary  

sed -n "1,$(($lo_start - 5))p" all.sql > start.sql
sed -n "$(($lo_start - 4)),$(($table_start - 2))p" all.sql > lo.sql
sed -n "$(($table_start - 1)),$(($blobs_start - 2))p" all.sql > tables.sql
sed -n "$(($blobs_start - 1)),$(($blobs_start + 4))p" all.sql > blobs_begin.sql
sed -n "$(($blobs_start + 5)),$(($commit_end - 1))p" all.sql > blobs.sql
sed -n "$(($commit_end - 0)),$(($commit_end + 1))p" all.sql > blobs_commit.sql
sed -n "$(($commit_end + 2)),$(($eof + 1))p" all.sql > end.sql

# split the large object and blob files to smaller peaces
# each record is 9 rows
mkdir -p lo
pushd lo 
split -l $((9 * 10000)) ../lo.sql lo_
popd

# there is a varying number of rows in each record, split from the empty lines
# collect line numbers of empty lines first
mkdir -p blobs
pushd blobs
cat ../blobs.sql | grep -n "^$" | cut -d ":" -f 1 > empty-lines
# then split the the line numbers to suitably sized pieces
split -l $((4 * 10000)) empty-lines blobs_

# finally, split the sql based on the last line number in each file
start=1
for f in $(ls blobs_*); do
	end="$(tail -n 1 $f)"
	echo $f $start $end
	sed -n "$(($start)),$(($end))p" ../blobs.sql > sql_${f}
	cat ../blobs_begin.sql sql_${f} ../blobs_commit.sql > trans_${f}
	rm sql_${f} ${f} 
	start=$(($end + 1))
done
popd

# restore
time cat start.sql | pv | psql --dbname $PGURL --username user

time ls lo/* | parallel -j 10 "cat {} | psql --dbname $PGURL --username user"

time cat tables.sql | pv | psql --dbname $PGURL --username user

time ls blobs/trans_blobs_* | parallel -j 10 "cat {} | psql --dbname $PGURL --username user"

time cat end.sql | pv | psql --dbname $PGURL --username user
```
