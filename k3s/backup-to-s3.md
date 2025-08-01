# Chipster's built-in backup feature

## Introduction

The built-in backup feature in Chipster is very much customised to our environment. We are using S3 compatible object storage to transfer the files and finally store a copy of the files on another archive server, which has a large storage volume.

Consider this only a temporary solution, because we may have to rely entirely on S3 in the future because of the growing data sizes. Unfortunately we don’t have a concrete plan how to do efficient incremental backups on S3 yet.

When configured properly, the Chipster's backup service dumps all three databases, compresses and uploads the files to a S3 object storage. Also an optional encryption can be configured. The file-storage service can do the same for the actual data files.

Then we have another standalone program `BackupArchive`, which we run on a remote archive server. It downloads the files from the S3 and stores them on a file system. This enables also incremental file backups. BackupArchive uploads a list of successfully copied files back to S3, so that next time the file-storage service can upload only new files that have appeared after the first backup.

These instructions will talk about Kubernetes instead of K3s, because this same information applies both to the K3s and OpenShift. All those share the same Kubernetes API and in this context those terms are interchangeable.

## How does it work?

### Databases and files

We want to backup Chipster databases and files. All database backups of an installation are taken care by a service called "backup" running in Kubernetes together with the actual API services. The reason for this separate service is that we might want to have multiple instances of the actual API service (like auth), but want to create only one backup.

File-storage stores users' files on a volume. We want this volume to be a block device volume, which usually are simpler and more reliable than shared file systems. Unfortunately, a block device can be mounted only to one host at the time in a Kubernetes cluster, so the backup service doesn't have access to these files, but file-storage has to do the file backups itself.

### Final backup storage in S3 or on archive server

There are two way to use this feature. You can configure only the upload part so that the S3 is your final backup storage. This will consume a lot of network bandwidth and storage space in S3, because the file-storage will make a full backup every time. In this case you also have to build your own system for cleaning up the old copies. Alternatively, you you can configure the whole system with the archive server. In this case file backups are made incrementally. A file system on the archive server is used for the final backup storage.

### Transfer through S3

The file transfer is similar for the database dumps and for the files. The backups in Kubernetes and object storage are temporary and only needed to transfer the files to archive server. The final backups on the archive server are called `archives` to distinguish them from the earlier copies in this process.

In Kubernetes:

- Compress (lz4), optionally encrypt (gpg) and package (tar) new files
- Upload the packages to the object storage

In the archive server

- Download packages from the object storage
- Extract the tar package (called an `archive` now)
- Clean up old archives from the archive server (keep enough to be able to restore old versions)
- Clean up old backups from the object storage (only latest kept)

### Incremental file backups

We take a full database backups every night, but we can't do the same for users' files, because that would consume too much space and often we couldn't even move them all in 24 hours. Let's assume the files are immutable. We'll do small changes to the above process to do incremental backups of files.

In Kubernetes:

- Get the list of files in the previous archive from the object storage and collect the list of all current files in file-storage. Backup only new files
- Upload also the list of all current files to the object storage

In the archive server

- Download the list of all current files from the object storage. Download the new files from the object storage and move the old files from the old archive version
- Upload the list of files in the latest archive
- Clean up only oldest archives. Individual archive version wouldn't be usefull without an unbroken chain of archives between that version to the latest

## Backup databases to S3

Chipster's backup service can compress and upload database backups to S3.

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

Select the `Maintenance` section in the [admin view](README.md#Admin-view) and click the button which starts a new backup of the session-db. Check the logs of the backup service to see that it worked. The backup service will create a new database backup every night from now on.

## Backup file-storage files to S3

Chipster's file-storage service can compress and upload backups of the users' data files to S3. If you configure an archive server too, these will be incremental copies.

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

Deploy, restart the pod, wait until the old pod has disappeared and check logs:

```bash
bash deploy.bash -f ~/values.yaml
kubectl rollout restart sts/file-storage
watch kubectl get pod
kubectl logs file-storage-0 --follow
```

In the admin view, click the button `Start backup`. Check the logs of the file-storage service to see that it worked.

## Archive server

### Setup archive server

There is a little program `BackupArchive` which can download backups from S3 to a server file system. This is ment to be run on a remote server, which is unlikely to be lost at the same time with the primary Chipster server. We'll call this `archive server`. This also enables incremental file backups. These instructions are written for Ubuntu 16.04.

Install Java with `SDKMAN!`:

```bash
# required by sdkman installer
sudo apt install -y unzip zip
curl -s "https://get.sdkman.io" | bash
```

Open a new terminal or run the "source" command printed by the `SDKMAN!` installation script.

List Java versions:

```bash
sdk list java
```

Install latest Java 11 version, e.g. from Amazon:

```bash
sdk install java 11.0.10.9.1-amzn
```

Create file `pull-and-build-code.bash`. This will be used to build the code now and later when
you want to update it.

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

Create file `archive.bash`. This is useful for running BackupArchive program manually, because
it shows the output directly on the screen.

```bash
#!/bin/bash
date
java -cp lib/*: fi.csc.chipster.archive.BackupArchive
```

Create folders for configuration and archives. Replace the second folder with a symlink, if you want to use another larger volume for storing the archives.

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

### Run BackupArchive program

Run:

```bash
bash archive.bash
```

### Schedule BackupArchive to run every night

Create file `cron-archive.bash`. This writes the program output to a file to allow you to see later what happened in the last scheduled run.

```bash
#!/bin/bash

# go to the script directory
cd $(dirname "$0")

# init SDKMAN! directly, because .bashrc refuses to run non-interactively in Ubuntu
source ~/.sdkman/bin/sdkman-init.sh

# run archive.bash, redirect stdout and stderr to a log file
bash archive.bash > cron.log 2>&1
```

Configure cron to run this every night at 06:12, or pick any other time. Run `crontab -e` to edit your crontab and add the following text. Replace `FULL_PATH_TO` with a path where your `cron-archive.bash` script is.

```
12 6 * * * bash FULL_PATH_TO/cron-archive.bash
```

If this doesn't work, change crontab time to run soon, use `sudo journalctl -u cron --follow` to see when it happens and then check the `cron.log` for possible error messages.

### Update archive server

TODO Update Ubuntu

Update `SDKMAN!` and Java:

```bash
sdk selfupdate
sdk update
# check if there are new minor Amazon Corretto 11 versions. Install if found
sdk list java
```

Pull latest code from GitHub and build it:

```bash
bash pull-and-build-code.bash
```

## Encryption

### Introduction

The built-in backup feature can encrypt the backups if you generate and configure encryption keys. It will encrypt both the database backups and file-storage file backups before those are uploaded to S3. It is designed on the assumption that the data in S3 is private, but encrypting the actual files adds an additional layer of protection, in case the S3 data is leakead. Note that the file checksums are not
encrypted, so an adversary could still check whether a specific file is in the backup or not.

### Generate keys

See https://help.github.com/en/articles/generating-a-new-gpg-key for more manual and more verbose instructions. The key generation seems to get easily stuck in a virtual machine because the Linux kernel doesn't have enough entropy to generate good quality random numbers.

Generate key (e.g. on your laptop):

```bash
echo -e "Key-Type: rsa
     Key-Length: 4096
     Name-Real: chipster
     Name-Email: chipster@localhost
     Expire-Date: 0
     %no-protection" | gpg --batch --generate-key
```

Find out the key id

```bash
gpg --list-secret-keys --keyid-format LONG | grep chipster@localhost -b2 | grep sec | cut -d "/" -f 2 | cut -d " " -f 1
```

Export the public key

```bash
gpg --armor --export KEY_ID
```

Export the private key. Encode with base64 to make it easier to store in password managers because the key itself is binary.

```bash
gpg --export-secret-keys KEY_ID | base64
```

Store these keys safely. We will configure the public key to Chipster soon. The private key is needed only in the restore operation. See a [later chapter](#How-to-manage-gpg-keys) includes instructions for removing the keys from your local gpg.

> Note! If you change the key, make sure the file-storage creates a full backup next time (e.g. by deleting the old backups from the object storage). Otherwise even your new file-storage backups will include the old files encrypted with the old key!

### Configure public key

Configure the public key in your `~/values.yaml` for the backup and file-storage services. The public key lines must be indented correctly to be recognized as a text block in the yaml format. Getting the indentation there is annoying. Usually code editors like [Visual Studio Code](https://code.visualstudio.com) can do this by selecting the text block and hitting the tab key a few times. Copy the whole key, even if this example is shortened to show only the first and last lines. Note that also the empty line must have correct number of indenting space characters and don't forget the vertical bar character `|` in the beginning to start the multiline text block.

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

Restart pods, wait until the old pod has disappeared and check the logs:

```bash
kubectl rollout restart deployment/backup
kubectl rollout restart sts/file-storage
watch kubectl get pod
kubectl logs deployment/backup
kubectl logs file-storage-0 --follow
```

Try to start a new backup in the admin view and follow the logs to see that it works.

If you are doing incremental backups to the archive server, remove the backups from the object storage (or their `archive_info` files) to get a full backup. This ensures that all backups from now on have only encrypted files.

### How to manage gpg keys

Import the private key to use it (-d and gpg2 in Ubuntu 16.04, -D and gpg in macOS)

```
echo -e PRIVATE_KEY | base64 -d | gpg2 --import
```

When you are done, delete the key from the keystore

```
gpg2 --delete-secret-keys chipster@localhost
gpg2 --delete-keys chipster@localhost
```

Make sure the keystore is empty

```
gpg2 --list-secret-keys
gpg2 --list-keys
```

## Restore

### Move files back to Chipster server

Copy an archived directory from the archive server to back to your Chipster server. If you have a direct SSH access between these servers, you can simply use standard command line tools like `rsync` to copy the directory. Otherwise, you can copy it through the object storage, for example using S3 client `awscli`.

Quick `awscli` tips:

```bash
# install
sudo apt install -y awscli

# login
aws configure set default.aws_access_key_id S3_ACCESS_KEY
aws configure set default.aws_secret_access_key S3_SECRET_KEY

# test
aws --endpoint-url https://a3s.fi s3 ls

# make bucket
aws --endpoint-url https://a3s.fi s3 mb s3://restore-test

# upload file
aws --endpoint-url https://a3s.fi s3 cp FILE s3://restore-test/

# download file
aws --endpoint-url https://a3s.fi s3 cp s3://restore-test/FILE .
```

### Decrypt and extract

[Import private key](#How-to-manage-gpg-keys) like instructed above.

If you want to decrypt and extract just one file:

```bash
gpg2 --decrypt FILE_ID.lz4.gpg | lz4 -d > FILE_ID
```

Or decrypt and extract all:

```bash
for f in $(find . | grep .lz4.gpg); do
  echo $f
  dir=$(dirname $f)
  basename=$(basename $f .lz4.gpg)
  gpg2 --quiet --decrypt $f | lz4 -d > $dir/$basename
  rm $f
done
```

Now you can continue with the general instructions for [restoring the database dump](backup.md#Restore-database-dump) and [restoring file-storage files](backup.md#Restore-file-storage-files) to copy the data from the Chipster virtual machine to the containers.

## Caveats

- The clean up of full backup archives keeps only the first of each day. Initiating additional backups in admin view uploads the backup to S3, but the next archiving will delete it
- Encryption after compression is generally a questionable practice because of the compression oracle attacks. However, this shouldn't be an issue in this case, because each file is compressed separately, so changing attackers own files can't reveal anything from the files of other users, even if the attacker would have an access to the backups over several backup cycles.
- File checksums are calculated before and after compression and encryption and stored in the backup_info and archive_info files. Those are not checked yet, but could be used later if file corruption is suspected.
