# Chipster behind proxy

These are installation instructions for Chipster server which has internet access only through a http proxy. These instructions are based on the [summary written by Oliver Heil](https://sourceforge.net/p/chipster/mailman/message/37336786/).

## Environment variables

Environment variables for a proxy setup are set in /etc/environment 

```
HTTP_PROXY="http://your.proxy:3128"
HTTPS_PROXY="http://your.proxy:3128"
NO_PROXY="localhost,127.0.0.0/8,0.0.0.0,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,chipstervm1,.your-domain.com,cattle-system.svc,.svc,.cluster.local"

http_proxy="http://your.proxy:3128"
https_proxy="http://your.proxy:3128"
no_proxy="localhost,127.0.0.0/8,0.0.0.0,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,chipstervm1,.your-domain.com,cattle-system.svc,.svc,.cluster.local"
```

Both upper and lower case variables were set. Change your.proxy and .your-domain.com and the proxy port 3128 to
your specific setting. (Rebooting the system so that all services get this environment is needed now).

Now following the [prerequesites](prerequisites.md), the proxy settings are automatically set in /etc/systemd/system/k3s.service.env

## Docker

The following needs to be created:

/etc/systemd/system/docker.service.d/http-proxy.conf

with content like:

```ini
[Service]
Environment="HTTP_PROXY=http://your.proxy:3128/";
Environment="HTTPS_PROXY=http://your.proxy:3128/";
Environment="NO_PROXY=localhost,127.0.0.0/8,0.0.0.0,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,chipstervm1,.your-domain.com,cattle-system.svc,.svc,.cluster.local"
```

Restart docker with

```bash
sudo systemctl restart docker
```

## Tools-bin package

Now further installation did work until tools-bin package.

The tools need to be installed manually according to <host-mount.md#tools-bin>.

Chipster 4 is now up and running.

## Environment variables for tools

Configure proxy variables to Chipster containers in your ~/values.yaml:

```yaml
deploymentDefault:
  env:
    http_proxy: "http://your.proxy:3128"
    https_proxy: "http://your.proxy:3128"
    no_proxy: "localhost,127.0.0.0/8,0.0.0.0,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,chipstervm1,.your-domain.com,cattle-system.svc,.svc,.cluster.local"
```
