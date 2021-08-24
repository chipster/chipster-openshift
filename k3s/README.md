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

However, K3s offers standardized way of doing all that and we don't want to implement ourselves functionalities that are already offered in the standard container cloud platforms, like HTTPS termination. K3s allows us to run small-scale Chipster in very similar environment, that we know well from our larger production installations. We aim to rely even more on the Kubernetes features in the future. For example, it would be nice to run each Chipster job in its own container. This would make it easier to manage tool dependencies and improve security. This kind of changes are probably a lot easier in the future, if the Chipster is already running in the container platform.

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

Most tools wont work yet, because we haven't downloaded the tools-bin package. But let's make a small test first to make sure that the most essential parts of the Chipster work. Upload some file to Chipster and run a tool `Misc` -> `Tests` -> `Test data input and output in Python`. If the result file appears in the Workflow view after few seconds, you can continue to the next chapter. If you encounter any errors, please try to solve them before continuing, because it's a lot easier and faster to change the deployment before you start the hefty tools-bin download.

We'll get to the tools-bin download soon, but let's take a quick look to the configuration system and updates first.

## Configuration and Maintenance

### Getting started with K3s

Please see [Getting started with K3s](getting-started-with-k3s.md) for K3s basics.

### Helm chart values

Deployment settings are defined in the `helm/chipster/values.yaml` file. You can override any of these values by passing `--set KEY=VALUE` arguments to the `deploy.bash` script (in addition to all the previous arguments), just like you have already done with the host name.

For example, to create a new user account `john` with a password `verysecretpassword`, you would check the file `values.yaml` to see which object needs to modified. 
You would run the `deploy.bash` scripte then again with an additional argument:

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

All Chipster configuration options can be found from a file [chipster-defaults.yaml](https://github.com/chipster/chipster-web-server/blob/master/src/main/resources/chipster-defaults.yaml). The `values.yaml` (explained in the previous chapter) has a `deployments.CHIPSTER_SERVICE.configs` map for each Chipster service, where you can set Chipster configuration key-value pairs. 

For example, edit your `~/values.yaml` to add the new setting.

>Note! The Helm templates now assume that all Chipster configuration values are strings. For example the number 5 here must be enclosed in quotes.

```yaml
deployments:
  comp:
    configs:
      comp-max-jobs: "5"
```

Then deploy Chipster again.

```bash
bash deploy.bash -f ~/values.yaml
```

If you want to change a setting only momentarily, you can pass it with `--set`, but this will be overriden in the next deploy with the value from your own or default `values.yaml`.

```bash
bash deploy.bash -f ~/values.yaml --set deployments.comp.configs.comp-max-jobs=\"10\"
```

You can check that configuration file was changed correctly.

```bash
$ bash get-secret.bash comp
url-int-service-locator: http://service-locator
service-password-comp: "PASSWORD_HIDDEN"    
comp-max-jobs: 5
```
Restart services.

```bash
bash restart.bash
```

Please note that two-word Chipster service names like `file-broker` are written with `camelCase` in the `deployments` map, i.e. `fileBroker` to make them easier to use in Helm templates.

### Updates

If you are going to maintain a Chipster server, you should subscribe at least to the [chipster-announcements](https://chipster.csc.fi/contact.shtml) email list to get notifications about new features and critical vulnerabilities. Consider subscribing to the [chipster-tech](https://chipster.csc.fi/contact.shtml) list too to share your experiences and learn from others.

TODO How to follow vulnerabilities in Ubuntu, Helm and K3s?

If you have just installed Chipster, you can simply skim through this chapter now and return here when it's time to update your installation.

> 2021-06-04 Note! The reverse proxy of the K3s called Traefik was updated in K3s version 1.21 requiring different configuration. This repository is now compatible only with K3s version 1.21 and newer. Check your K3s version with a command `k3s --version`. If it is older than 1.21, please update K3s first before updating Chipster.

Pull latest changes from the deployment repository.

```bash
git pull
```

Install latest package repositories etc. This will also install the latest K3s and Helm.

```bash
ansible-playbook ansible/install-deps.yml -i "localhost," -c local -e user=$(whoami)
```

Update operating system packages on the host (including Docker and Ansible).

```bash
sudo apt update
sudo apt upgrade -y
```

Restart the server to make sure all new packages are taken in use.

```bash
sudo shutdown -r 0
```

Pull the latest images and update deployments, assuming that you have created your own `~/values.yaml`. The second run puts back the default pull policy `IfNotPresent`, so that you can restart pods without pulling images in every restart. 

```bash
bash deploy.bash -f ~/values.yaml --set image.localPullPolicy=Always
bash deploy.bash -f ~/values.yaml
```

Restart all pods.

```bash
bash restart.bash
```

### Download the tools-bin package

When you have checked that the Chipster itself works, you can start the tools-bin download. There are two ways to do it. This chapter shows the more automatic version, where you simply configure the tools-bin version and the deployment scripts will start a Kubernetes job to do the download. Alternatively, you could [mount a host directory](host-mount.md#tools-bin) and then do the download manually.

To let the deployment scripts do the download, simply run the deployment again, but set the tools-bin version this time. Check the latest tools-bin version from the [file list](https://a3s.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/). Don't worry if the latest tools-bin version there looks older than the latest Chipster version. It probably means only that the tools-bin package hasn't changed since that version.

Set the tools-bin version in your `~/values.yaml`.

```yaml
toolsBin:
  version: chipster-3.15.6
```

And deploy Chipster again.

```bash
bash deploy.bash -f ~/values.yaml
```

That will also will print you insctructions for how to follow the progress of the download and how to restart pods when it completes.

### Admin view

 * check the password of `admin` user account from the auth

 ```bash
 kubectl exec deployment/auth -it -- cat security/users
 ```

 * when logged in with that account, there is `Admin` link in the top bar of the web app. Click that link to see the Admin view.

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
### JWT keys

Chipster services `auth` and `session-db` create authentication tokens. These are JWT tokens that are signed with a private key. Other Chipster services can request the corresponding public key from the Rest API of these services to validate these tokens. The private key is generated in `generate-passwords.bash` and must be kept secret. 

TODO How to generate new keys if the old keys have leaked?

#### OpenID Connect

A separate document has instructions for [authenticating Chipster users with OpenID Connect](oidc.md) protocol.

#### LDAP authentication

Instructions for [LDAP authentication](ldap.md) are provided in a separte docuemnt.
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

 * check the password of `example_session_owner` from the auth (see the [Admin view](#admin-view) topic above)
 * login with that account and create same sessions
 * share them as read-only to user ID `everyone`

Check the latest example sessions version from the [file list](https://a3s.fi/swift/v1/AUTH_chipcld/chipster-example-sessions/). Don't worry if the latest tools-bin version there looks older than the latest Chipster version. It probably means only that the example-sessions hasn't changed since that version.

The page lists the current example sessions. Concatenate the address of the page and one of those lines to download individual sessions. Make sure you have `https` in front of the address, because the server doesn't repond to download requests in plain `http`.

TODO write script for downloading, uploadin and sharing all example sessions

### Support request sessions

TODO
 * [configure](#chipster-settings) support email address on `session-worker`
 * check the password of `support_session_owner` from auth (see the [Admin view](#admin-view) topic above)
 * login with that account too see the support request sessions

### Remote management

TODO copy kubectl configuration from the host and use `kubectl` from your laptop

### K3s cluster

TODO 
 * How to handle possible custom images? Copy manually to each node or setup an image registry?
 * How to handle PVCs? Setup a NFS share or Longhorn?
 * How to scale the cluster up and down?
 * How to scale Chipster inside the cluster?

### Tool development

[Building a new container image](build-image.md) from version control repository is a good way to ensure that all hosts in a Kubernetes cluster are running the same version and the history of all previous versions is stored. However, commits and builds are usually too slow for any interactive development work. There many ways to edit files faster:

1. Open a shell with `kubectl exec` to the container and edit files directly in the container.
2. Edit files on the host or on your laptop and copy files with with `kubectl cp` to the container.
3. [Mount a directory of the host to the container](host-mount.md). Edit the files on the host or copy them from your laptop to the host.

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
