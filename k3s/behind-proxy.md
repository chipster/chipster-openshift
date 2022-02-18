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

The tools need to be installed manually to a [hostMount volume](host-mount.md#tools-bin).

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

## Appendix 1: How to setup http proxy in OpenStack

These instructions show how to setup a simple squid proxy to test Chipster installation. For any real use, you may want to setup more strict configuration and security group rules.

* Let's assume there is a security group "default", which allows outbound connections
* Create a new security group which allows Chipster to connect to the proxy. Let's call it "sg_proxy".Allow Egress and Ingress from and to the other machines in this same group, using any TCP port. 
* Launch two virtual machines (VM), one for the proxy and one for Chipster
   * Proxy VM's security groups should include "default", "sg_proxy" and allow your SSH access
   * Chipster VM's security groups should include "sg_proxy" and allow your SSH and HTTP connections. Add the security group "default" for the first boot to allow the VM to fetch your SSH key. Then remove it, to force it use the proxy from now on
   * You probably need to add a floating IP to the Chipster VM to access Chipster with your browser from your laptop

Install squid:

```bash
sudo apt install squid
```

Preserve the original squid config:

```bash
cd /etc/squid/
sudo cp squid.conf squid.conf.original
sudo chmod a-w squid.conf.original
```

Allow anyone to use this proxy (but security groups allow only members of sg_proxy). Change `http_access deny all` to `http_access allow all`:

```bash
sudo nano squid.conf
sudo systemctl restart squid
```

Test that outbound connections fail in the Chipster VM:

```bash
curl chipster.csc.fi
```

Configure proxy environment variables like shown above on this page. Check that the above `curl` command now works through the proxy. You can also check squid logs:

```bash
tail -f /var/log/squid/access.log 
```