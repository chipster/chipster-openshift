# Configure TLS encryption
## Introduction

Chipster can use TLS (https) to encrypt and validate the network traffic between the browser and server. These instructions will show you how to get a free TLS certificate from [Let's Encrypt](https://letsencrypt.org) for Chipster.

## DNS name

Let's Encrypt doesn't issue certificates for plain IP addresses, so you must have a DNS name for your server to use it. Make sure that you have also configured this DNS name as `host` in your `~/values.yaml`, instead of the plain IP address.

## Firewall

For Let's Encrypt to verify that you control your server, your firewall must allow 
- inbound connections from anywhere to port 80
- outbound connections to port 443 anywhere, but usually all outbound connections are allowed anyway

 If you are not quite sure about your server configuration yet, there are tips for working with more strict firewall configuration in the last chapter.

## Install cert-manager

We'll install [cert-manager](https://cert-manager.io/docs/), which gets certificates from the Let's Encrypt. 

This will show a short version of cert-manager installation. You can find more details from [the original manual page](https://cert-manager.io/docs/installation/kubernetes/).

Use Ansible playbook to add the Helm repository of cert-manager and install its CustomResourceDefinitions.

```bash
ansible-playbook ansible/install-tls-deps.yml -i "localhost," -c local -e user=$(whoami)
```

Now we only have to install cert-manager itself with Helm. If you have already a previous version of the cert-manager installed, uninstall it first: `helm --namespace cert-manager uninstall cert-manager`.

```bash
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.11.0
```

## Rate limits

Let's Encrypt issues two kinds of certificates: `staging` and `production`. The production certificates have e.g. a [rate limit](https://letsencrypt.org/docs/rate-limits/) of 5 certificates per week for one DNS name. You can check the number of your current certificates by [searching on crt.sh](https://crt.sh/). If you exceed the limit, you may have to wait up to a week until you can try again or change your DNS name. 

Browsers won't trust the staging certificates, but use those first when getting familiar with Let's Encrypt and cert-manager to avoid hitting the production rate limits.

## Get a staging certificate

First, we'll configure cert-manager to use the Let's encrypt staging environment. Add this to your `~/values.yaml` file. Replace `EMAIL_ADDRESS` with the address where you want to receive certificate expiration notifications, in case something goes wrong with the automatic certificate renewal.

```yaml
tls:
  env: "staging"
  email: EMAL_ADDRESSS
```

Then deploy the new settings:

```bash
bash deploy.bash -f ~/values.yaml
```

The cert-manager will try to get a staging certificate for you. Check that the certificate was issued:

```bash
$ kubectl get certificate
NAME           READY   SECRET         AGE
chipster-tls   True    chipster-tls   4s
```

If the certificate isn't ready after a while, check once more your firewall configuration (described above) and check the events of the following objects:

```bash
kubectl describe certificate
kubectl describe certificaterequest
kubectl describe order
```

Seeing that the certificate is ready is actually enough at this point. This certificate is only from the Let's encrypt staging environment, so browsers won't trust it anyway. 

## Get a production certificate

After you have succesfully received a staging certificate, it's time to get a real one. In your `~/values.yaml`, change the `env` to `prod` and keep your email address for the certificate expiration notifications.

```yaml
tls:
  env: "prod"
  email: EMAL_ADDRESSS
```

Again, deploy the new settings. Restart also all deployments to make sure that they can still connect to each other.

```bash
bash deploy.bash -f ~/values.yaml
bash restart.bash
```

Wait until this production certificate is ready. Follow the troubleshooting tips in `staging` chapter above if that doesn't happen.

```bash
$ kubectl get certificate
NAME           READY   SECRET         AGE
chipster-tls   True    chipster-tls   48s
```

Now open the address https://HOST_ADDRESS in the browser. You should see a closed lock icon in the address bar. If you click on that icon, the browser should show you a valid certificate for you HOST_ADDRESS issued by Let's Encrypt.

The TLS termination in K3s is done by a reverse proxy called Traefik. If the browser keeps showing Traefik's self-signed certificate or Let's Encrypt's staging certificate, try again in a new browser tab or try to restart Traefik:

```bash
kubectl rollout restart deployment/traefik -n kube-system
```

## Certificate renewal behind a firewall

Let's encrypt certificates are valid for 90 days. In the final configuration you must either have port 80 open all the time for cert-manager to renew the certificate automatically, or renew the certificate periodically yourself to keep the firewall port closed otherwise.

To renew the certificate manually, open the firewall port, delete the the old certificate (`kubectl delete secret chipster-tls`) and cert-manager should get a new one in a few seconds. After that you can close the firewall port again.

TODO Will the renewal work if we keep port 80 open but 443 closed?
