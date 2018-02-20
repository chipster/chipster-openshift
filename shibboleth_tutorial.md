# Shibboleth authentication for Java in OpenShift

## Introduction

Federated Identity Management allows a service to authenticate users with their existing credentials. Often research federations have chosen to use [SAML2 protocol](https://en.wikipedia.org/wiki/SAML_2.0) between the services. In this tutorial we setup a new service, which uses a SAML2 federation to authenticate its users. 

Our service will be a new Service Provider (SP) in SAML2-speak. When the user needs to authenticate, her browser is redirected to her organization's own login page (Identity Provider, IdP), which takes care of the checking user's credentials and passing the authentication information back to our service.

The Shibboleth SP software is probably the most popular implementation for SAML2 Service Provider. It consists of two parts, an Apache module *mod_shib* and a daemon service *shibd*.

This tutorial shows how to get the authentication information to a small example service written in Java. What you do then with this information depends on the architectural style of your application. If you are building a monolithic application, you will probably build your whole application behind this Apache web server. On the other hand, in a microservice architecture this would be just another simple microservice, which will only trigger your own authentication system.

There are two ways to pass to authentication information from Apache to your application: *request environment variables* and *HTTP headers*. The Shibboleth documentation favors the first one, but it may not be possible in all programming languages.  With a quick googling it looks like request environment variables work in Java and Python for example, but maybe not in NodeJS. If you decide to use language where only HTTP headers are supported, please make sure you understand its [security implications](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPSpoofChecking).

The tutorial assumes you have the command line tools `oc` (OpenShift command line client), `wget` and `jq` (for parsing yaml) already installed on your development machine. 

## Container

First we will install necessary software to an image and deploy it. It won't do anything useful until it's configured, but at least we see that the container starts. 

### Build Shibboleth image

We'll use a dockerfile to build an image with *Apache*, *mod_shib* and *shibd* installed.  

Some parts of the code are copied here for illustration, but please see the [shibboleth dockerfile](dockerfiles/shibboleth/Dockerfile) for the complete and latest version. 

Let's start from the plain ubuntu image

```dockerfile
FROM ubuntu:16.04
```

Install Apache, mod_shib and shibd

```dockerfile
RUN apt install -y shibboleth-sp2-common libapache2-mod-shib2 apache2 shibboleth-sp2-utils
```	

It's not allowed to run services with root privileges in OpenShift at the moment. We have to make some adjustments to allow Apache and shibd to run as a regular user. The OpenShift will create a new user (with high UID) for running these services and adds that user a group `root`, so it's enough to give necessary permissions for that group.  

```dockerfile
RUN chgrp -R root /var/log/apache2/ /var/lock/apache2/ /var/run/apache2/ \
	&& chmod -R g+w /var/log/apache2/ /var/lock/apache2/ /var/run/apache2/
```	

By default Apache tries to bind to port 80, which isn't allowed for normal users. Let's disable that by replacing the  file with an empty file. We'll add a new minimal configuration file to `sites-enabled` to be able to test that Apache starts. It will be overridden by the real configuration later. 
	
```dockerfile
RUN mv /etc/apache2/ports.conf /etc/apache2/ports.conf.original \
	&& echo "Listen 8000" > /etc/apache2/sites-enabled/shibboleth.conf \
	&& touch /etc/apache2/ports.conf 
```

We are going to configure the Apache and shibd by mounting a new directtory (called *secret* in OpenShift) containing the configuration files. For Apache we can simply mount it to `/etc/apache2/sites-enabled`, where Apache will automatically look for all files ending with `.conf`. On the contrary, shibd has a lot of configuration files in the same directory and we want to replace only some of them, so we can't simply replace the whole directory. Instead we create a new directory `/etc/shibboleth/secret` and replace the relevant configuration files with a symlink pointing to that directory. The default `shibbleth2.xml` is copied to the folder `secret` so that we can test that the *shibd* starts even before we have configured it. 


```dockerfile 	
RUN mkdir /etc/shibboleth/secret \
	&& cd /etc/shibboleth \
	&& cp shibboleth2.xml secret/shibboleth2.xml \
	&& mv shibboleth2.xml shibboleth2.xml.original \
	&& mv attribute-map.xml attribute-map.xml.original \
	&& ln -s secret/shibboleth2.xml shibboleth2.xml \
	&& ln -s secret/attribute-map.xml attribute-map.xml
```	
	
Also shibd expects rights to write in a few directories under `/var` like Apache.

```dockerfile
RUN mkdir -p /var/run/shibboleth /var/cache/shibboleth /var/log/shibboleth \
	&& chgrp -R root /var/run/shibboleth /var/cache/shibboleth /var/log/shibboleth \
	&& chmod -R g+w /var/run/shibboleth /var/cache/shibboleth /var/log/shibboleth
```	
	
Set the command for starting services. Usually each process should be in its own container, but these pocesses were made to 
run in the same machine. Starting two processes like this won't handle the shutdown signals correctly (`exec` fixes it only for one process), so your login requests may fail during the deployments. If you try to fix this with a process manager like *supervisord*, be warned that the shibd process saves same state about the login session, which probably has to sorted out also to get error-free rolling updates.

```dockerfile
CMD ["bash", "-c", "/etc/init.d/apache2 start; exec shibd -F start"]
```

Now we have the dockerfile and we can build an image in OpenShift. Unfortunately the `oc` command doesn't accept the file path directly, but we have pass it from the standard input.

```bash
oc new-build --name shibboleth -D - < dockerfiles/shibboleth/Dockerfile
```

Most likely you have to update the dockerfile every now and then. You can do it in *OpenShift console* (the OpenShift web app), but I prefer keeping the original on my laptop for easier version control. It pays off to build [a small bash script](update_dockerfile.bash) for replacing the dockerfile in OpenShift with your local version like this:

```bash
bash update_dockerfile.bash shibboleth
oc start-build shibboleth --follow
```

### Deploy Shibboleth

The image is ready. Let's deploy it.

```bash
oc new-app shibboleth
```

Expose the Apache's port 8000 and terminate the TLS on the load balancer. Disable redirects from *http* to *https* by setting `--insecure-policy=None`, because the same is recommended also in more traditional setups (where TLS is terminated in the Apache). This will use a OpenShift's wildcard TLS certificate. Consider getting a host-specific certificate and terminating the TLS in the Apache instead. I'm not aware of any direct risk associated with this wildcard solution, but your own certificate would be definitely better. 

```bash
oc expose dc shibboleth --port=8000  	
oc create route edge --service shibboleth --port 8000 --insecure-policy=None
```

See the OpenShift console (the web app). In the Overiew view you should see your application and its URL address starting with *https*. We are going to need this URL many times later, so let's call it SERVICE_URL. Click that link and you should see Apache's welcome page. Change the address to *SERVICE_URL/Shibboleth.sso/Session* and the mod_shib will tell you that your don't have an authentication session yet.

## Configuration

Now that the container starts, it's time to configure it. Unfortunately quite many things have to be set correctly until we can test that all these pieces work together. We configure the Apache web server, generate new cryptographic keys, configure the shibd daemon and finally register our new service to the federation. After all this is done, we are able to test the login procedure and we are ready to start building our own application.  

### Configure Apache

Create a directory for the configuration files, perhaps under a private version control repository.

```bash
mkdir -p ../PRIV_REPO/confs/apache/
```

Create file `shibboleth.conf` to this directory. The only thing we need to change is the last line. We have to tell the SERVICE_URL for the mod_shib. The mod_shib needs to know that its external address starts with `https://` due to the TLS termination in the load balancer. 

```apache
# reverse proxy module
LoadModule proxy_module /usr/lib/apache2/modules/mod_proxy.so

# apache documentation recommends a http proxy, but we go with ajp, because only it
# supports request environment variables, strongly endorsed by the shibboleth documentation                                                                                                                                     
LoadModule proxy_ajp_module /usr/lib/apache2/modules/mod_proxy_ajp.so

# listen to a high port because we don't have root privileges
Listen 8000                                                                                                                             
                                                                                                                                                                                                  
<Location "/secure">

	# proxy to Tomcat                                                                                                                                                                              
	ProxyPass "ajp://localhost:8012"
	
	# use mod_shib for authentication
	# apache needs both AuthType and Require                                                                                                                                                          
	AuthType shibboleth                                                                                                                                                                                                                                                                                                                           
	Require shibboleth
	
	# login if there is no session                                                                                                                                                                        
	ShibRequestSetting requireSession true
	
</Location>                                                                                                                                                                                       
                                                                                                                                                                                                  
# mod_shib needs to know the route address (with https) to generate correct urls 
ServerName SERVICE_URL
```

Create a OpenShift *secret* from this Apache configuration file. There is a small script [update_apache_confs.bash](update_apache_confs.bash) which you can use to update the configuration later. 

```bash
bash update_apache_confs.bash ../PRIV_REPO/confs/apache/
```

Mount the Apache configuration secret.

```bash
oc set volume dc/shibboleth --add -t secret --secret-name shibboleth-apache-conf --mount-path /etc/apache2/sites-enabled
```
### Generate keys

We need a private key and its certificate to sign our authentication messages to the IdP and decrypt information we get from it. Luckily a self-signed certificate is enough, so we can simply generate these. We are going to generate the key in the container and then copy it to your laptop.

The first parameter is the hostname of the service, for which SERVICE_URL works fine. The second parameter is the entityID of your service. Basically you can invent any unique string for it, but SERVICE_URL is a good choice. We need some place with write permissions to save the keys for a minute. We'll use /tmp now, because there we have write permissions. The permissions don't allow the shib-keygen to change the permissions and group of the key files, but that doesn't matter, because you can do it later on your own machine. There should be a `oc cp` command for copying files, but for some reason it didn't do anything (`oc cp shibboleth:/tmp/sp-cert.pem ~/secure/sp-cert.pem`), so I used `oc rsh` instead.

Store the private key sp-cert.pem in a such place on your computer that you don't accidentally  make it public (for example by pushing it to a code repo). I'll use the dir `~/secure/` in these exapmles. The second file, `sp-cert.pem` will be public anyway, but let's keep it in the same directory, because we are going to use them together.

```bash
oc rsh dc/shibboleth shib-keygen -h SERVICE_URL -y 3 -e SERVICE_URL -o /tmp
mkdir ~/secure/
oc rsh dc/shibboleth cat /tmp/sp-key.pem > ~/secure/sp-key.pem
oc rsh dc/shibboleth cat /tmp/sp-cert.pem > ~/secure/sp-cert.pem
chmod go-rwx ~/secure/sp-key.pem
oc rsh dc/shibboleth rm /tmp/sp-*.pem
```

```
> Generating a 2048 bit RSA private key
> ....................................................+++
> ......................+++
> unable to write 'random state'
> writing new private key to '/var/run/shibboleth/sp-key.pem'
> -----
> chown: changing ownership of '/var/run/shibboleth/sp-key.pem': Operation not permitted
> chown: changing ownership of '/var/run/shibboleth/sp-cert.pem': Operation not permitted
> chgrp: changing group of '/var/run/shibboleth/sp-key.pem': Operation not permitted
> chgrp: changing group of '/var/run/shibboleth/sp-cert.pem': Operation not permitted
> command terminated with exit code 1
```

The SAML2 metadata describes all the member SPs and IdPs of the federation. The federation signs it with their own private key and we can check its authenticity with their certificate. Download their certificate to the same folder.

```bash
wget https://wiki.eduuni.fi/download/attachments/27297785/haka_testi_2015_sha2.crt -O ~/secure/metadata.crt
```

### Configure shibd

After the keys are generated, we are ready to start configuring the shibd daemon.

Create a directory also for the shibd configuration files next to the Apache configuration.

```bash
mkdir -p ../PRIV_REPO/confs/shibd/
```

Copy the default configuration files shibboleth2.xml and attribute-map.xml from the container.

```bash
oc cp dc/shibboleth:/etc/shibboleth/shibboleth2.xml.original ../PRIV_REPO/confs/shibd/shibboleth2.xml
oc cp dc/shibboleth:/etc/shibboleth/attribute-map.xml.original ../PRIV_REPO/confs/shibd/attribute-map.xml
```

Configure the shibboleth2.xml according to the instructions of your federation (e.g. [Haka testi in Finnish](https://wiki.eduuni.fi/display/CSCHAKA/Shibboleth+SP+asennus)). 

Fill in the `entityID` you used in when generating the keys, most likely your SERVICE_URL. Set `signing="front"`, because authentication requests must be signed with your private key in Haka. Set `attributePrefix="AJP_"`, because the Apache mod_ajp_proxy will pass through only variables starting with prefix `AJP_`.

```xml
<ApplicationDefaults entityID="SERVICE_URL" REMOTE_USER="eppn persistent-id targeted-id" signing="front" encryption="false" attributePrefix="AJP_">
```

Configure the Discovery Service (former WAYF), where a user can select her own organization.

```xml
<SSO discoveryProtocol="SAMLDS" discoveryURL="https://testsp.funet.fi/shibboleth/WAYF"> SAML2 </SSO>
```

Set the support email address, which is shown in error messages. For example open the SERVICE_URL/Shibboleth.sso/does-not-exist in browser to see an error page.

```xml
<Errors supportContact="SUPPORT@EMAIL" logoLocation="/shibboleth-sp/logo.jpg" styleSheet="/shibboleth-sp/main.css"/>
```

Find out the address of the federation's SAML2 metadata. Configure it's address and the necessary filter according to the federation's requirements.

```xml
<MetadataProvider type="XML" uri="https://haka.funet.fi/metadata/haka_test_metadata_signed.xml" backingFilePath="secret/backing_metadata.xml" reloadInterval="3600">
 <SignatureMetadataFilter certificate="/etc/shibboleth/secret/metadata.crt"/>
 <MetadataFilter type="RequireValidUntil" maxValidityInterval="2592000"/>
</MetadataProvider>
```

Configure the file names of your private key and certificate, which we just generated. We are going mount them to /etc/shibboleth/secret next. 

```xml
<CredentialResolver type="File" key="/etc/shibboleth/secret/sp-key.pem" certificate="/etc/shibboleth/secret/sp-cert.pem"/>
```

Create a OpenShift Secret from these shibd configuration files, keys and certificates using a script [update_shibd_confs.bash](update_shibd_confs.bash). 

```bash
bash update_shibd_confs.bash ~/secure/ ../PRIV_REPO/confs/shibd/
```

Mount the shibd configuration dir.

```bash
oc set volume dc/shibboleth --add -t secret --secret-name shibboleth-shibd-conf --mount-path /etc/shibboleth/secret
```

### Register SP

Your service is ready to be registered. In case of Haka, go to [Haka resource registry](https://rr.funet.fi/rr). Create a new Service Provider. Fill in the following details:

**Organiztion information**

Select your organization.

**SP Basic Information**

| Setting                                             | Value
| --------------------------------------------------- |---
| Entity Id                                           | SERVICE_URL
| Service Name (Finnish)                              | 
| Service Description (Finnish)                       | 
| Service Login Page URL                              | SERVICE_URL/Shibboleth.sso/Login
| Discovery Response URL                              | SERVICE_URL/Shibboleth.sso/Login
| urn:oasis:names:tc:SAML:2.0:nameid-format:transient | x
  
**SP SAML Endpoints**

| Setting                                             | Value
| --------------------------------------------------- |---
| URL index #1                                        | SERVICE_URL/Shibboleth.sso/SAML2/POST

**Certificates**

Click *Add new certificate*  and copy the contents of the file ~/secure/sp-cert.pem to the text field (without the first and last line).

**Requested Attributes**

Select the attributes you need and explain why. See 
- [Haka Attribute Test Service](https://rr.funet.fi/haka/) to see your own information
- [Test Haka Attribute Test Service(https://testsp.funet.fi/haka/) to see the attributes of the test user (you will get the credentials after you have registered)
- [Schema documentation](https://wiki.eduuni.fi/display/CSCHAKA/funetEduPersonSchema2dot2)

Our example application will use two attributes:

| Setting                  | Selected | Reason
| ---                      | ---      | ---
| eduPersonPrincipalName   | x        | Technical user identifier
| cn                       | x        | Human-readable name of the user

In Test-Haka, select at least the `cn` attribute, becuase the test user's name contains an accented character, which allows
us to test a character encoding issue later. 

**UI Extensions**

None

**Contact Information**

| Setting          | Value
| ---              | ---
| Contact type     | Technical
| First Name       | 
| Last Name        | 
| E-Mail           | 
| Contact type     | Support
| First Name       | 
| Last Name        | 
| E-Mail           | 

Click *Submit SP Description* and you should get an email when the federation has processed your registration. The email contains the credentials of the test account, which you can use to log in to your service. Navigate a browser to `SERVICE_URL/Shibboleth.sso/Login`. You should be redirected first to the Discovery Service and then to the Login form. Fill in the credentials of the test user and you should be back in your own service. See 'SERVICE_URL/Shibboleth.sso/Session`and now you should have an active authentication session. You can logout by going to 'SERVICE_URL/Shibboleth.sso/Logout`.

If this doesn't work, see Apache log file
```bash
oc rsh dc/shibboleth cat /var/log/apache2/error.log
```
*shibd* log file
```bash
oc rsh dc/shibboleth cat /var/log/shibboleth/shibd.log
```

Your service's metadata
```bash
curl SERVICE_URL/Shibboleth.sso/Metadata
```

### Configure attribute mapping

Before your service gets the attributes you requested, those must be mapped. By default only to eduPersonPrincipalName attribute is mapped to "eppn" variable. Edit the file ~/PRIV_REPO/confs/shibd/attribute-map.xml and uncomment or add the mapping for your attributes. The `urn:oid:`refers to the *cn* attribute and this maps it to the variable with the same name. 

```xml
<Attribute name="urn:oid:2.5.4.3" id="cn"/>
```

Update the configuration files.

```bash
bash update_shibd_confs.bash ~/secure/ ../PRIV_REPO/confs/shibd/
```

Login again in 'SERVICE_URL/Shibboleth.sso/Login` and now you should see your new attributes listend in 'SERVICE_URL/Shibboleth.sso/Session`. The values are hidden, but don't worry, you will see them soon in our test application.

## Application
### Java project

### Java build
