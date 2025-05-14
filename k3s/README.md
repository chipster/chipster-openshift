# Chipster in K3s

## Overview

These instructions show how to install the Chipster web app version 4 to an Ubuntu server.

Chipster is based on microservice architecture. There is about a dozen different services, but each of service tries to be relatively simple and independent. Each service is run in its own container. The containers are orchestrated with [Lightweight Kubernetes K3s](https://k3s.io).

The user interface in the v4 Chipster is a single-page-application (SPA) running in the user's browser. [Commnad line client](chipster-cli.md) and Rest APIs are also available.

## Status

To get started as fast as possible, these instructinos assume that were are setting up a new single-node server. At this point we don't promise to offer complete instructions for updating this server to new Chipster versions later. Especially migrating the user's sessions and files from one version to another is not always trivial. We do try to provide [the critical pointers](migration.md), because we are migrating our own installations anyway.

These instructions will assume that you are running the latest version of deployment scripts and container images. If you have installed your Chipster server earlier, please [update](#Updates) it first to the latest version or find the old version of these insructions from the time when your server was installed.

## Why K3s

K3s is a Lightweight Kubernetes, effectively a container cloud platform. Do we really need the cointainer cloud platform to run a few server processes on single host? Not really, you could checkout the code yourself and follow the Dockerfiles to see what operating system packages and what kind of folder structure is needed for each service, how to compile the code and how to start the processes. Add some form of reverse proxy to terminate HTTPS (e.g. Apache or nginx) and some process monitoring (Java Service Wrapper or systemd) and you are done.

However, K3s offers standardized way of doing all that and we don't want to implement ourselves functionalities that are already offered in the standard container cloud platforms, like HTTPS termination. K3s allows us to run small-scale Chipster in very similar environment, that we know well from our larger production installations. Also the current Chipster analysis tools assume to be run with specific container images, which would be difficult to arrange without some kind of container system.

## Installation

### Prerequisites

Please follow a separate document [Chipster in K3s prerequisites](prerequisites.md) to make sure that you have necessary hardware resources, K3s, Helm and a few other utilities installed.

### Deploy

First we generate passwords.

Helm doesn't seem to have a standard way for handling passwords. Our solution is to have a separate bash script which generates the passwords and stores them in a Kubernetes secret. The passwords are stored in a same format as the `values.yaml` in the Chipster Helm chart.

```bash
bash generate-passwords.bash
```

Download dependencies.

```bash
helm dependency update helm/chipster
```

Then we deploy the Chipster itself. Replace `HOST_ADDRESS` with host machine's public IP address or DNS name.

The script takes the passwords from the `passwords` secret that we just created.

```bash
bash deploy.bash --set host=HOST_ADDRESS
```

See when pod's are running (hit Ctrl + C to quit).

```bash
watch kubectl get pod
```

Many Chipster services can't start before some other Chipster service is running. It may take up to 15 minutes before all services are ready. If they don't start, follow the [Getting started with K3s](getting-started-with-k3s.md) to find out why.
If many services don't work, check the services `auth`, `service-locator` and `session-db` first, in this order.

The `deploy.bash` script above showed you the address of the Chipster web app, which you can open in your browser. It will also print the credentials of the `chipster` account that you can use to log in to the app. Run `helm status chipster` to see it again. Make sure the address starts with `http://` and not `https://`. Browsers are eager to use the latter, but then the app can't connect to the Rest APIs, that are using only `http://` for the time being.

If something goes wrong in the deployment and you want to start from scratch, see the chapter [Uninstall Chipster](#uninstall-chipster).

Most tools wont work yet, because we haven't downloaded the tools-bin package. But let's make a small test first to make sure that the most essential parts of the Chipster work. Upload some file to Chipster and run a tool `Misc` -> `Tests` -> `Test data input and output without tools-bin`. If the result file appears in the Workflow view after few seconds, you can continue to the next chapter. If you encounter any errors, please try to solve them before continuing, because it's a lot easier and faster to change the deployment before you start the hefty tools-bin download.

We'll get to the tools-bin download soon, but let's take a quick look to the configuration system and updates first.

## Configuration and Maintenance

### Getting started with K3s

Please see [Getting started with K3s](getting-started-with-k3s.md) for K3s basics.

### Helm chart values

Deployment settings are defined in the `helm/chipster/values.yaml` file. You can override any of these values by passing `--set KEY=VALUE` arguments to the `deploy.bash` script (in addition to all the previous arguments), just like you have already done with the host name.

For example, to create a new user account `john` with a password `verysecretpassword`, you would check the file `helm/chipster/values.yaml` to see which object needs to modified.
You would run the `deploy.bash` script then again with an additional argument:

```bash
--set users.john.password=verysecretpassword
```

More instructions about the `--set` argument can be found from the [Helm documentation](https://helm.sh/docs/intro/using_helm/).

Managing all the changes in the arguments becomes soon overwhelming. It's better to create your own `values.yaml`, to your home directory for instance, which could look like this:

```yaml
host: HOST_ADDRESS

users:
  john:
    password: "verysecretpassword"
```

You can then simply pass this file to the deployment script.

```bash
bash deploy.bash -f ~/values.yaml
```

If you need to debug this process, you can run the above command with `--debug --dry-run` options to see how Helm processes the values.

### Chipster settings

All Chipster configuration options can be found from a file [chipster-defaults.yaml](https://github.com/chipster/chipster-web-server/blob/master/src/main/resources/chipster-defaults.yaml). The `helm/chipster/values.yaml` (explained in the previous chapter) has a `deployments.CHIPSTER_SERVICE.configs` map for each Chipster service, where you can set Chipster configuration key-value pairs.

For example, edit your `~/values.yaml` to add the new setting (most tools require one "slot", so this will effectively limit the number of jobs to five).

> Note! The Helm templates now assume that all Chipster configuration values are strings. For example the number 5 here must be enclosed in quotes.

```yaml
deployments:
  scheduler:
    configs:
      scheduler-bash-max-slots: "5"
```

Then deploy Chipster again.

```bash
bash deploy.bash -f ~/values.yaml
```

If you want to change a setting only momentarily, you can pass it with `--set`, but this will be overriden in the next deploy with the value from your own or default `values.yaml`.

```bash
bash deploy.bash -f ~/values.yaml --set deployments.scheduler.configs.scheduler-bash-max-slots=\"10\"
```

You can check that configuration file was changed correctly.

```bash
$ bash get-secret.bash scheduler
url-int-service-locator: http://service-locator
service-password-comp: "PASSWORD_HIDDEN"
cheduler-bash-max-slots: |-
  10
```

Restart services to force Chipster to read the configuration files again.

```bash
bash restart.bash
```

Please note that two-word Chipster service names like `file-broker` are written with `camelCase` in the `deployments` map, i.e. `fileBroker` to make them easier to use in Helm templates.

### Specify container image version

See the next chapter.

### Updates

#### Introduction to Chipster updates

Even if you have just installed a new Chipster server, it's recommended to follow this chapter. It includes instructions for specifying a container image version and pulling all images, which makes sure your Chipster installation doesn't break when new versions are released.

If you are going to maintain a Chipster server, you should subscribe at least to the [chipster-tech](https://chipster.2.rahtiapp.fi/contact) email list to get notifications about critical vulnerabilities. Consider subscribing to the [chipster-announcements](https://chipster.2.rahtiapp.fi/contact) list too which focuses on the new analysis features for end-users.

Before starting the update, please make sure you have the necessary [backups](#backups) in case something goes wrong in this process.

If you plan to maintain a single node Chipster server for a longer period of time, consider storing data on [hostPath volumes](change-k3s-version.md), which makes it easier to reinstall K3s if ever needed.

TODO How to follow vulnerabilities in Ubuntu, Helm and K3s?

#### Select Chipster version

> 2024-10-08 Note! The Chipster versions up to v4.11.1 used PostgreSQL version 11 and PostgreSQL 14 is used since Chipster version v4.12.0. Please [update the PostgreSQL and migrate the data](update-postgres.md) before updating from v4.11.1 (or older) to v4.12.0.

> 2025-05-12 Note! The Chipster versions up to `v4.14.2` used K3s version `v1.26.4` and Ubuntu `20.04`. Since Chipster version `v4.15.0`, K3s `v1.32.4` and Ubuntu `24.04` are used. Please follow [K3s instructions](migration.md#update-to-k3s-v1324) **before** updating to v4.15.0. You can update [Ubuntu](migration.md#update-to-ubuntu-2404) before or after updating Chipster.

In the initial configuration Chipster did pull the latest container images, but setting a specific image version makes sure the deployment scripts and all your images are compatible with each other.

Chipster images are available in two different places. These instructions show how to use the most recent image versions which are available in an image registry. There is separate page for [older image versions](image-archive.md), which are stored in object storage.

Run the following command to see what image versions are available in the image registry. For example, the output could look something like this:

```bash
$ curl -s https://image-registry.apps.2.rahti.csc.fi/v2/chipster-images/base/tags/list -H "Authorization: Bearer anonymous" | jq .tags[] -r | sort --version-sort
latest
v4.13.15
v4.14.0
v4.14.0-rc1
v4.14.1
v4.14.2
v4.15.0
```

Usually you should select the newest version, which doesn't have letters "-rc" (short for "release candidate").

#### Update Chipster to selected version

Pull the correct version of the deployment repository. Replace `v4.15.0` with a version you chose in the previous chapter. We won't update the version numbers in these instructions after every release, so make sure to check the latest versions like shown above.

```bash
cd ~/git/chipster-openshift/k3s
git checkout v4.15.0
git pull
```

Configure the chosen version also in your `~/values.yaml`. Keep it there until it's time to update to the next Chipster version.

```yaml
image:
  tag: v4.15.0
```

Install latest package repositories etc. This will also install the latest K3s (compatible with Chipster) and Helm.

```bash
ansible-playbook ansible/install-deps.yml -i "localhost," -c local -e user=$(whoami)
```

Check if new passwords need to be generated:

```bash
bash generate-passwords.bash
```

Pull the configured version of the images to make sure your installation keeps working even if our image repository isn't available:

```bash
bash pull-images.bash
```

Configure Chipster to use that image version. This will be taken in use soon after the Ubuntu reboot forces containers to restart.

```bash
bash deploy.bash -f ~/values.yaml
```

Update operating system packages on the host (including Ansible). These commands give you the latest updates of the Ubuntu 24.04. Our plan is to migrate next to Ubuntu 28.04 after it's released. We recommend staying in the Ubuntu version 24.04 until we have tested the migration.

TODO Prevent Ubuntu from advertising `do-release-upgrade` at login?

```bash
sudo apt update
sudo apt upgrade -y
```

Restart the server to make sure all new packages and container images are taken in use.

```bash
sudo shutdown -r now
```

See also the next chapter for instructions how to update the tools-bin package.

### Download the tools-bin package

The tools-bin package contains most of the Chipster analysis tool program binaries and all reference data. Its size is about 500 GB and it has hundreds of thousands files. Its download can be challenging if the internet connection is less than perfect and also simply creating so many files may take hours on some high-latency file systems.

When you have checked that the Chipster itself works, you can start the tools-bin download. If you are updating your Chipster server, you should check also if there is newer tools-bin version available. New analysis tools or new reference genome versions are added in the new tools-bin version. Usually most old tools continue working even if you don't update to the latest tools-bin version.

There are two ways to download the tools-bin. This chapter shows the more automatic version, where you simply configure the tools-bin version and the deployment scripts will start a Kubernetes job to do the download. Alternatively, you could [mount a host directory](tools-bin-host-mount.md) and then do the download manually.

To let the deployment scripts do the download, simply configure the tools-bin version and run the deployment again. Use to following command to check the available tools-bin versions. Don't worry if the latest tools-bin version there is older than the latest Chipster version. It means only that the tools-bin package hasn't changed since that version.

```bash
curl -s https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/ | cut -d "/" -f 1 | sort | uniq
```

Set the tools-bin version in your `~/values.yaml`.

```yaml
toolsBin:
  version: chipster-4.9.0
```

And deploy Chipster again.

```bash
bash deploy.bash -f ~/values.yaml
```

That will also will print you insctructions for how to follow the progress of the download and how to restart pods when it completes.

If you updated the tools-bin version, you can free disk space by removing the old version. Check the name of the old tools-bin volume:

```bash
kubectl get pvc
```

Remove it:

```bash
kubectl delete pvc NAME_OF_OLD_TOOLS_BIN_VOLUME
```

### Admin view

- check the password of `admin` user account from the auth

```bash
kubectl exec deployment/auth -it -- cat security/users
```

- when logged in with that account, there is `Admin` link in the top bar of the web app. Click that link to see the Admin view.

### Custom DB queries

Postgres databases are defined as a dependency of the Chipster Helm chart. When you deploy the Chipster Helm chart, also the databases are deployed.

If you want to make custom queries to the databases, you can run the `psql` client program in the database container.

```bash
kubectl exec statefulset/chipster-session-db-postgresql -it -- bash -c 'psql postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost/$POSTGRES_DB'
```

Single quotes (`'`) are important so that your local shell doesn't try to expand the variables, which are only defined inside of the container.

### HTTPS

[Configure Chipster to use TLS](tls.md) (https) to encrypt and validate the network traffic between the browser and the server.

### Authentication

#### JWT keys

Chipster service `auth` creates authentication tokens. These are JWT tokens that are signed with a private key. Other Chipster services can request the corresponding public key from the Rest API of these services to validate these tokens. The private key is generated in `generate-passwords.bash` and must be kept secret.

You can generate a new private key if you want invalidate all current authentication tokens. First take a copy of the current secret `passwords`:

```bash
kubectl get secret passwords -o json > ~/passwords-backup.json
```

Use this one-liner to remove the old key from the secret:

```bash
kubectl get secret passwords -o json | jq '.data."values.yaml"="'"$(kubectl get secret passwords -o json | jq '.data."values.yaml"' -r | base64 -d | jq  'del(.tokens)' | base64)"'"' | kubectl apply -f -
```

Generate a new key:

```bash
bash generate-passwords.bash
```

Generate new configuration secrets for each service, restart all services and wait until old pods have disappeared:

```bash
bash deploy.bash -f ~/values.yaml
bash restart.bash
watch kubectl get pod
```

If all services started properly and you are able to log in to Chipster, you can remove the copy of the passwords secret:

```bash
rm ~/passwords-backup.json
```

If something goes wrong, you can restore your old passwords. Note! Make sure that you have your original database passwords in `~/passwords-backup.json`, because those are the most difficult to change. If the database passwords are there, you can delete the current secret, apply the old version and deploy the changes:

```
# Only for reverting to the old passwords!
kubectl delete secret passwords
kubectl apply -f ~/passwords-backup.json
bash deploy.bash -f ~/values.yaml
bash restart.bash
watch kubectl get pod
```

#### OpenID Connect

A separate document has instructions for [authenticating Chipster users with OpenID Connect](oidc.md) protocol.

#### LDAP authentication

Instructions for [LDAP authentication](ldap.md) are provided in a separate document.

#### File authentication

There is a file `security/users` on `auth`, just like in the old Chipster v3, but it won't survive container restarts. The easiest way to add new users is through [values.yaml](#helm-chart-values).

### Backups

Every disk will fail eventually, bugs may delete the data or administrators can make mistakes. Please make sure you take [backups](backup.md) from your server or make sure
your users understand that they may lose the files they have stored in your Chipster server.

### Logging

TODO Collect logs with Filebeat (running in a sidecar container) and push them to Logstash

See [logging.md](logging.md) to change logging levels.

### Grafana

TODO Collect statistics from the admin Rest API, push them to InfluxDB and show in Grafana

### Monitoring and session replay tests

TODO Configure ReplayServer

### Customize front page, contact details and terms of use

[You can customize the front page](custom-html.md) and other html pages. It would be good to write at least
what kind of usage is allowed on your server, who is maintaining it and how to contact you in case there
are any issues.

### Example sessions

- check the password of `example_session_owner` from the auth (see the [Admin view](#admin-view) topic above)
- login with that account and create same sessions
- share them as read-only to user ID `everyone`

Check the latest example sessions version from the [file list](https://a3s.fi/swift/v1/AUTH_chipcld/chipster-example-sessions/). Don't worry if the latest tools-bin version there looks older than the latest Chipster version. It probably means only that the example-sessions hasn't changed since that version.

The page lists the current example sessions. Concatenate the address of the page and one of those lines to download individual sessions. Make sure you have `https` in front of the address, because the server doesn't repond to download requests in plain `http`.

TODO write script for downloading, uploading and sharing all example sessions

### Support request sessions

TODO

- [configure](#chipster-settings) support email address on `session-worker`
- check the password of `support_session_owner` from auth (see the [Admin view](#admin-view) topic above)
- login with that account too see the support request sessions

### Remote management

TODO copy kubectl configuration from the host and use `kubectl` from your laptop

### K3s cluster

TODO

- How to handle possible custom images? Copy manually to each node or setup an image registry?
- How to handle PVCs? Setup a NFS share or Longhorn?
- How to scale the cluster up and down?
- How to scale Chipster inside the cluster?

See also the page [Chipster cluster](chipster-cluster.md) for the instructions about the number of replicas for each Chipster service.

### Tool development

The page [Tool script development](tool-script-dev.md) provides instructions for changing and and adding new tools to your Chipster
server.

### Container images

When running Chipster in containers, the program itself, tool scripts and operating system packages come from the container images. By default these images are pulled from
public repositories. If you want to change anything in the images, you can [build your own container images](build-image.md).

### Uninstall Chipster

Command `helm uninstall chipster` should delete all Kubernetes objects, except volumes. This is relatively safe to run when you want run the installation again, but want to keep the data volumes. Use `kubectl delete pvc --all`, if you want to delete the volumes too.

The `helm uninstall chipster` command gives you almost a fresh start with one caveat. The databases store their password on their volumes. If you generate the passwords again, the databases won't accept the new passwords. In the early phases when you don't have anything valuable in the databases, it's easiest to simply delete the database volumes too.

If the Helm release is too badly broken for the uninstallation, you can delete everything manually with `kubectl`.

```bash
for t in job deployment statefulset pod secret ingress service pvc; do
    kubectl delete $t --all
done
```
