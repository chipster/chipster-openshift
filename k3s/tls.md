# Configure TLS encryption
## Introduction

Chipster can use TLS (https) to encrypt and validate the network traffic between the browser and server.

## DNS name

Let's encrypt doesn't issue certificates for plain IP addresses, so must have a DNS name for your server to use this. Make sure that you have also configured this DNS name as `host` in your `values.yaml`, instead of the plain IP address.

## Firewall

Your firewall must allow inbound connections from anywhere to port 80, for Let's encrypt to check that you really control this server. Let's encrypt also needs outbound connections to port 443, but usually all outbound connections are allowed. If you are not quite sure about your server configuration yet, you can put back more strict firewall rules after you the cert-manager has retrieved the final production certificate. 

## Install cert-manager

We'll install [cert-manager](https://cert-manager.io/docs/), which isssues certificates from the free [Let's encrypt](https://letsencrypt.org/) service. 

This will show a short version of cert-manager installation. You can find more details from [the original manual page](https://cert-manager.io/docs/installation/kubernetes/).

Create the namespace for cert-manager:

```bash
$ kubectl create namespace cert-manager
```

Add a Helm repository and update your local Helm chart repository cache:

```bash
$ helm repo add jetstack https://charts.jetstack.io
$ helm repo update
```

Install the CustomResourceDefinitions:

```bash
$ kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.1/cert-manager.crds.yaml
```

Install cert-manager with Helm:

```bash
$ helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v0.15.1
```

## Rate limits

Let's encrypt issues two kinds of certificates: `staging` and `production`. The production certificates have e.g. a [rate limit](https://letsencrypt.org/docs/rate-limits/) of 5 certificates per week for one domain. You can check the number of your current certificates by [searching on crt.sh](https://crt.sh/). If you exceed the limit, you may have to wait up to a week until you can try again. Browsers won't trust the staging certificates, but use those first when getting familiar with Let's encrypt and cert-manager to avoid hitting the production rate limits.

## Get a staging certificate

Next, we'll configure cert-manager to use the Let's encrypt stagin environment.

Create a staging ClusterIssuer. Replace `EMAIL_ADDRESS` with the address where you want to receive certificate expiration notifications, in case somethign goes wrong with the automatic renewal.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: EMAIL_ADDRESS
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01: 
        ingress: {}
EOF
```

Let's try to get a staging certificate to see that everything works. Replace `HOST_ADDRESS` with server's DNS name.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: chipster-tls
  namespace: default
spec:
  secretName: chipster-tls
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  commonName: HOST_ADDRESS
  dnsNames:
  - HOST_ADDRESS
EOF
```

Check that the certificate was issued:

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

Remove everything related to this test:

```bash
kubectl delete clusterissuer letsencrypt-staging
kubectl delete certificate chipster-tls
kubectl delete secret chipster-tls
```

# Get a production certificate

Now it's time to configure the production ClusterIssuer. Only the name and url has changed from the staging. Configure also the email address for the certificate expiration notifications.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: EMAIL_ADDRESS
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01: 
        ingress: {}
EOF
```

The certificate object could be created implicitly by adding annotations to the Ingress object. However, we'll do it now separately, because otherwise we would repeat the annotations in our each and every ingress. Next, create the certificate object. Set the `HOST_ADDRESS` also here.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: chipster-tls
  namespace: default
spec:
  secretName: chipster-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: HOST_ADDRESS
  dnsNames:
  - HOST_ADDRESS
EOF
```

Wait until this proudction certificate is ready.

```bash
$ kubectl get certificate
NAME           READY   SECRET         AGE
chipster-tls   True    chipster-tls   48s
```
## Apply

Finally, configure the deployment to use this certificate. In case of `nginx-test`, you can configure it by adding the following parameter to your deployment command (first you may have to delete your previous release with `helm uninstall nginx-test`):

```bash
--set ingress.tls[0].secretName=chipster-tls
```

In case of the actual Chipster deployment, you can add this to your `values.yaml`:

```yaml
ingress:
  tls:
    - secretName: chipster-tls
```

Now open the address https://HOST_ADDRESS in the browser. You should see a closed lock icon in the address bar. If you click on that icon, the browser should show you a valid certificate for you HOST_ADDRESS issued by Let's Encrypt.

## Certificate renewal behind a firewall

Let's encrypt certificates are valid for 90 days. In the final configuration you must either have port 80 open all the time for cert-manager to renew the certificate automatically, or renew the certificate periodically yourself to keep the firewall port closed otherwise.

To renew the certificate manually, open the firewall port, delete the the old certificate (`kubectl delete secret chipster-tls`) and cert-manager should get a new one in a few seconds. After that you can close the firewall port again.
