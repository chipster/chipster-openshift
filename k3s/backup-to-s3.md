# Backup Chipster server to S3
## Introduction

The built-in backup functionality in Chipster is very much customised to our environment. We are using S3 compatible object storage to transfer the files and finally store a copy of the files on another archive server, which has a large NFS volume. 

Consider this only a temporary solution, because we may have to rely entirely on S3 in the future because of the growing data sizes. Unfortunately we don’t have a concrete plan how to do efficient incremental backups on S3 yet. 

When configured properly, the Chipster's backup service dumps all three databases, compresses, encrypts and uploads the files to a S3 object storage. The file-storage service can do the same for the users’ files. 

Then we have another standalone program `BackupArchive`, which we run on that remote archive server. It downloads the files from the S3 and stores them on the NFS volume. It will upload a list of successfully copied files back to S3, so that next time the file-storage service can upload only new files that have appeared after the first backup.

These instructions will talk about Kubernetes instead of K3s, because this same information applies both to the K3s and OpenShift. All those share the same Kubernetes API and in this context those terms are interchangeable.

## How does it work?

### Databases and files

We want to backup Chipster databases and files. All database backups of an installation are taken care by a service called "backup" running in Kubernetes together with the actual API services. The reason for this separate service is that we might want to have multiple instances of the actual API service (like auth), but want to create only one backup.
At the moment file-broker stores users' files on a volume. 

We want to store the files on a block device volumes, which usually are simpler and more reliable than shared file systems. Unfortunately, in a Kubernetes cluster that can be mounted only to one host at the time, so the backup-service doesn't have access to these files, but file-broker has to do backups itself.

### Transfer to or through S3

There are two way to use this. You can configure only the upload part so that the S3 is your final backup storage. In this case you have to build your own system for cleaning up the old copies. Or you you can configure the whole system, where you need use a file system on the archive server for the main backup storage.

The file transfer is similar for the database dumps and for the files. The backups in Kubernetes and object storage are temporary and only needed to transfer the files to archive server. The final backups on the archive server are called `archives` to distinguish them from the earlier copies in this process.

In Kubernetes:
- Compress (lz4), encrypt (gpg) and package (tar) new files
- Upload the packages to the object storage

In the archive server
- Download packages from the object storage
- Extract the tar package (called an `archive` now)
- Clean up old archives from archive server (keep enough to be able to restore old versions)
- Clean up old backups from the object storage (only latest kept)

### Incremental file backups

We take a full database backups every night, but we can't do the same for users' files, because that would consume too much space and often we couldn't even move them all in 24 hours. Let's assume the files are immutable. We'll do small changes to the above process to do incremental backups of files.

In Kubernetes:
- Get the list of files in the previous archive from the object storage and collect the list of all current files in file-broker. Backup only new files
- Upload also the list of all current files to the object storage

In the archive server
- Download the list of all current files from the object storage. Download the new files from the object storage and move the old files from the old archive version
- Upload the list of files in the latest archive
- Clean up old only oldest archives. Individual archive version wouldn't be usefull without an unbroken chain of archives between that version to the latest

Example

There are two files `a` and `b` in the file-storage and no previous backups. When the file-storage server creates the backup:
- There is no `archive_info` file in the object storage, so a full backup is needed
- file-broker compresses, encrypts, packages and uploads files `a` and `b` to the object storage
- file-broker uploads a `backup_info` file, which includes files `a` and `b` (and their sizes and checksum before and after compression and encryption) to the object storage

On the next run the archiver:
- Finds the backup from the object storage
- Downloads and extracts (only the outermost tar, files remain compressed and encrypted) the file packages from the object storage, storing the files `a` and `b` to the `download` folder
- Creates a dir with the backup's timestamp for this new archive
- Goes through the `backup_info` file and moves the files `a` and `b` from the `download` folder to the latest archive folder
- Uploads a `archive_info` file which declares that files `a` and `b` are archived

Let's assume the file `a` is deleted and a new file `c` is added to the file-storage. On the next backup
- file-storage finds the previous `archive_info` file
- file-storage goes through its current files. The file `b` is found from the `archive_info`, so its information is simply copied to the `backup_info`. The new file `c` is compressed, encrypted, packaged and uploaded to the object storage and its information written to the `backup_info` too

On the next run the archiver:
- Finds the backup from the object storage
- Downloads and extracts the file package from the object storage, storing the file `c` to the `download` folder
- Creates a dir with the backup's timestamp for this new archive
- Goes through the `backup_info` file and moves the file `b` from the previous archive folder and the file `d` from the `download` folder the latest archive folder. The file `a` remains in the previous folder, which will be deleted after 60 days
- Uploads a `archive_info` file which declares that files `b` and `c` are now archived

## Backup databases to S3

> Note! Our `chipster-web-server` image has `pg_dump` version 9 which refues to work with the PostgreSQL version 11 installed by our K3s instructions. We are unable to fix the this right now, so please use the backup to file system instructions to backup databases in K3s for now.

Chipster's backup service can encrypt and upload database backups to S3.

Configure the endpoint, region, access key, secret key and bucket of your S3 object storage in your `~/values.yaml`. Only the most important options are shown here. Please see the [chipster-defaults.yaml](https://github.com/chipster/chipster-web-server/blob/prod/src/main/resources/chipster-defaults.yaml) for all available backup settings.

```yaml
deployments:
  backup:
    configs:
      backup-s3-endpoint: a3s.fi
      backup-s3-region: regionOne
      backup-s3-access-key: ""
      backup-s3-secret-key: ""
      backup-bucket: ""
      backup-time: 01:10
```

Deploy, restart the pod, wait until the old pod has disappeared and check logs:

```bash
bash deploy.bash -f ~/values.yaml
kubectl rollout restart deployment/backup
watch kubectl get pod
kubectl logs deployment/backup --follow
```

Open the admin view by logging to Chipster as username `admin`, click `Admin` from the top navigation bar. Select the `Maintenance` section from the left and click the button which start a new backup of the session-db. Check the logs of the backup service to see that it worked. The backup service will create a new database backup every night from now on.

## Backup users' data files to S3

Chipster's file-storage service can encrypt and upload backups of the users' data files to S3. If you have a archive server, these will be incremental copies.

Configure backups for `file-storage` just like shown for database in the previous chapter.

```yaml
deployments:
  fileStorage:
    configs:
      backup-s3-endpoint: a3s.fi
      backup-s3-region: regionOne
      backup-s3-access-key: ""
      backup-s3-secret-key: ""
      backup-bucket: ""
      backup-time: 01:10
```

Deploy, restart the pod,  wait until the old pod has disappeared and check logs:

```bash
bash deploy.bash -f ~/values.yaml
kubectl rollout restart sts/file-storage
watch kubectl get pod
kubectl logs file-storage-0 --follow
```

In the admin view, click the button `Start backup`. Check the logs of the file-storage service to see that it worked. 

## Archive server

There is a little program `BackupArchive` which can download backups from S3 to a local disk on the archive server. These instructions are written for Ubuntu 16.04.

Install Java with `SDKMAN!`:

```bash
# required by sdkman installer
sudo apt install -y unzip zip
curl -s "https://get.sdkman.io" | bash
# open a new terminal or run the "source" command printed by the script
```

List Java versions:

```bash
sdk list java
```

Install latest Java 11 version, e.g. from Amazon:

```bash
sdk install java 11.0.10.9.1-amzn
```

Create file `pull-and-build-code.bash`:
```bash
#!/bin/bash

set -e

pushd git/chipster-web-server; git pull; ./gradlew distTar -Dfile.encoding=UTF-8; popd

pushd lib
  tar -xzf ../git/chipster-web-server/build/distributions/chipster-web-server.tar.gz
  rm -f *.jar
  cp chipster-web-server/lib/* .
  rm -rf chipster-web-server
popd
```

Checkout and build code:

```bash
mkdir git lib
pushd git
git clone https://github.com/chipster/chipster-web-server.git
popd
bash pull-and-build-code.bash
```

Configure:
```bash
mkdir conf backup-archive
```

Create file `conf/chipster.yaml` and configure the S3 settings. You can check these from the Chipster server by running a command `bash get-secret.bash file-storage`. 

```yaml
backup-s3-endpoint: a3s.fi
backup-s3-region: regionOne
backup-s3-access-key: S3_ACCESS_KEY
backup-s3-secret-key: S3_SECRET_KEY
backup-bucket: k3s-backup-test
```

Run:

```bash
java -cp lib/*: fi.csc.chipster.archive.BackupArchive
```

TODO schedule cron to run this daily.

## Encryption

### Introduction

The built-in backup system can encrypt the backups if you generate and configure encryption keys.

### Generate keys

See https://help.github.com/en/articles/generating-a-new-gpg-key for more manual and verbose instructions. The key generation seems to get easily stuck in a virtual machine because the Linux kernel doesn't have enough entropy to generate good quality random numbers. 

Generate key (e.g. on your laptop):

```
echo -e "Key-Type: rsa
     Key-Length: 4096
     Name-Real: chipster
     Name-Email: chipster@localhost
     Expire-Date: 0
     %no-protection" | gpg --batch --generate-key
```
    
Find out the key id

```
gpg --list-secret-keys --keyid-format LONG | grep chipster@localhost -b2 | grep sec | cut -d "/" -f 2 | cut -d " " -f 1
```

Export the public key

```
gpg --armor --export KEY_ID
```

Export the private key. Encode with base64 to make it easier to store in password managers because the key itself is binary.

```
gpg --export-secret-keys KEY_ID | base64
```

Store these keys safely. Well configure the public key to Chipster soon. The private key is needed only in the restore operation. The next chapter includes instructions for removing the keys from your local gpg. 

>If you change the key, make sure the file-storage creates a full backup next time (e.g. by deleting the old backups from the object storage). Otherwise even your new file-storage backups will include the old files encrypted with the old key!

### Configure the public key

Configure the public key in your `~/values.yaml` for the backup and file-storage services. The public key lines must be indented correctly to be recognized as a text block in the yaml format. Getting the indentation there is annoying. Usually code editors like [Visual Studio Code](https://code.visualstudio.com) can do this by selecting the text block and hitting the tab key a few times. Copy the whole key, even if this example is shortened to show only the first and last lines. Note that also the empty line must have correct number of indenting space characters.

```yaml
deployments:
  backup:
    configs:
      backup-gpg-public-key: |
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        mQINBGB5bcEBEADI4JcsIQ7E5NAWRya3byWWd3RYyD3GX3Ev2m7w+bf/nviF5gNC
        ...
        7mjkLUrfbtbPNOI4f/Q7tMiF5o7sgNDIbUhvScX8D+LPms5IyY8rr0TDbpgYqjD4
        =LMMJ
        -----END PGP PUBLIC KEY BLOCK-----
  fileStorage:
    configs:
      backup-gpg-public-key: |
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        mQINBGB5bcEBEADI4JcsIQ7E5NAWRya3byWWd3RYyD3GX3Ev2m7w+bf/nviF5gNC
        ...
        7mjkLUrfbtbPNOI4f/Q7tMiF5o7sgNDIbUhvScX8D+LPms5IyY8rr0TDbpgYqjD4
        =LMMJ
        -----END PGP PUBLIC KEY BLOCK-----
```

Restart pods, wait until the old pade has disappeared and check the logs:

```bash
kubectl rollout restart deployment/backup
kubectl rollout restart sts/file-storage
watch kubectl get pod
kubectl logs deployment/backup
kubectl logs file-storage-0 --follow
```

Try to start a new backup in the admin view and follow the logs to see that it works.

If you are doing incremental backups to the archive server, remove the backups from the object storage (or their `archive_info` files) to get full backup. This ensures that all backups from now have only encrypted files. 

### How to manage keys in gpg

Import the private key to use it (-d and gpg2 in Ubuntu 16.04, -D and gpg in OSX)

```
echo -e PRIVATE_KEY | base64 -d | gpg2 --import
```

When you are done, delete the key from the keystore

```
gpg --delete-secret-keys chipster@localhost
gpg --delete-keys chipster@localhost
```

Make sure the keystore is empty

```
gpg --list-secret-keys
gpg --list-keys
```

## Restore

Copy a archived directory from the archive server to back to hour Chipster server. This example uses `awscli` command to transfer it throught the object storage. If you have a direct SSH access between these server, you can of course simply use standard command line tools like `rsync` to copy the directory.

TODO install `awscli` to the archive and Chipster servers.

In the archive server:

```bash
# Login to object storage
aws configure set default.aws_access_key_id S3_ACCESS_KEY
aws configure set default.aws_secret_access_key S3_SECRET_KEY

# test
aws --endpoint-url https://a3s.fi s3 ls

# make bucket
aws --endpoint-url https://a3s.fi s3 mb s3://restore-test

# package a backup directory
tar -cvf restore.tar file-storage-backup_2019-05-08T09\:26\:17.038Z

# upload the package
aws --endpoint-url https://a3s.fi s3 cp restore.tar s3://restore-test/
```


In the Chipster server:

```bash
# configure object storage credentials
aws configure set default.aws_access_key_id S3_ACCESS_KEY
aws configure set default.aws_secret_access_key S3_SECRET_KEY

mkdir storage/restore
cd storage/restore
# download
aws --endpoint-url https://a3s.fi s3 cp s3://restore-test/restore.tar .
# extract
tar -xf restore.tar
cd file-broker-backup_2019-05-08T09\:26\:17.038Z/

# import private key like instructed above

# if you want to decrypt just one file
gpg2 --decrypt FILE_ID.lz4.gpg | lz4 -d > FILE_ID

# or decrypt all
for f in $(find . | grep .lz4.gpg); do
  echo $f
  dir=$(dirname $f)
  basename=$(basename $f .lz4.gpg)
  gpg2 --quiet --decrypt $f | lz4 -d > $dir/$basename
  rm $f
done
```

## Caveats

- The clean up of full backup archives keeps only the first of each day. Initiating additional backups in admin view uploads the backup to S3, but the next archiving will delete it
- Encryption after compression is generally a questionble practice because of the compression oracle attacks. However, this shouldn't be an issue in this case, because each file is compressed separately, so changing attackers own files can't reveal anything from the files of other users, even if the attacker would have an access to the backups over several backup cycles.
- File checksums are calculated before and after compression and encryption and stored in the backup_info and archive_info files. Those are not checked yet, but could be used later if file corruption is suspected. 
