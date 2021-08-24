# Authenticating Chipster users with LDAP
## Introduction

Chipster v4 supports LDAP authentication through JAAS configuration just like the old v3. 

## Test on command line

It's a good idea to get familiar with LDAP queries manually before doing the same in Chipster configuration. This example uses a command line tool `ldapsearch`.

```bash
ldapsearch -x -H LDAP_SERVER/ -D BIND_DN -W -b BASE_DN
```

* The `LDAP_SERVER` is the address and port of our LDAP server, something like `ldaps://ldap.example.com:636`.
* Your `BIND_DN` is something like: `'cn=USERNAME,ou=people,dc=example,dc=com'` and basically is your (horribly long) username for the LDAP server.
* `BASE_DN` is the starting point of the search, for example: `'ou=people,dc=example,dc=com'`. This defines the group of users that you want to allow.

Chipster tries to do a similar LDAP query, when an end-user wants to log in. The USERNAME here in the BIND_DN is end-user's short username, for example "jsmith". When you run the `ldapsearch` command above, it will ask user's password and then shows the search results, if the authentication was accepted.

## LdapLoginModule

When you have a working query on the command line, you can put together the `jaas.config` file. On the command line you probably had your (short) username written to your BIND_DN. Replace those with a string `{USERNAME}`. The LdapLoginModule will replace all occurrances of this with the username provided by the end user.

Chipster's default jaas.config file is included in the compiled jar packages. To add your own jaas.config file, you must add two entries to your `~/values.yaml`:

```yaml
deployments:
  auth:
    configs:
      auth-jaas-conf-path: "conf/jaas.config"
    conf:
      jaas.config: |
        /** Login Configuration for Chipster **/
        Chipster {
          fi.csc.chipster.auth.jaas.SimpleFileLoginModule sufficient passwdFile="security/users";
          com.sun.security.auth.module.LdapLoginModule sufficient
            userProvider="LDAP_SERVER/BASE_DN"
            authIdentity="BIND_DN"
            useSSL=true
            debug=true;
        };

```

The first part will add the option `auth-jaas-conf-path` to the `auth`'s configuration file in `conf/chipster.yaml`. It will make `auth` to load the jaas.config from the given file path instead of the default file in the jar pacakge.

The second part will create that file to `conf/jaas.config` and define its contents. Yaml block style, started by the pipe character `|`, allows us to embed other file formats in this yaml file. Just make sure that you indent all the lines with a consistent number (or more) space characters. Indenting with tab charactes is not allowed in yaml. 

This example enabled the SimpleFileLogin, just like in the default configuration. It authenticates your local accounts. You probably want to keep it enabled here too for the admin access.

See [JAAS LdapLoginModule](https://docs.oracle.com/javase/8/docs/jre/api/security/jaas/spec/com/sun/security/auth/module/LdapLoginModule.html) for more information about configuring the LdapLoginModule.

Deploy the configuration and restart `auth`:

```bash
bash deploy.bash -f ~/values.yaml
kubectl rollout restart deployment/auth
```

See when new auth has started and the old has disappeared:

```bash
kubectl get pod
```

Finally, follow auth logs while you try to log in to Chipster:

```bash
kubectl logs deployment/auth --follow
```

## LdapExtLoginModule

In the case where LDAP requires initial binding using a known service account you can use the class LdapExtLoginModule from the [JBOSS project](http://www.jboss.org/).

### Problem description

Every user with an account in our Active Directory Domain should be able to log into chipster using the Active Directory login credentials. The JAAS LdapLoginModule does not provide initial binding with a service account to the LDAP, but we can use LdapExtLoginModule from JBOSS.

### Solution

LdapExtLoginModule is part of [PicketBox library](https://picketbox.jboss.org), which is already included in the Chipster container images. The LdapLoginModule chapter above shows how to configure the jaas.config in Chipster. Just change the `LdapLoginModule` part in the jaas.config with this `LdapExtLoginModule` configuration.

Loggging from LdapExtLoginModule is enabled on `debug` level by default. If this is too much information, please see the [logging instructions](logging.md) to change the level to `info`, for example.

Example configuration provided by Oliver Heil:

```
          org.jboss.security.auth.spi.LdapExtLoginModule REQUIRED
            java.naming.provider.url="ldap://your.ldap.server:389"
            bindDN="your_active_directory_name\\your_ldap_search_user"
            bindCredential="your_ldap_search_user_password"
            baseCtxDN="OU=your_ou,DC=some_more,DC=your_domain,DC=com"
            baseFilter="(&(objectClass=user)(cn={0}))"
            rolesCtxDN="OU=your_ou,DC=some_more,DC=your_domain,DC=com"
            roleFilter="(&(objectClass=user)(cn={0}))"
            roleAttributeID="memberOf"
            allowEmptyPasswords="false";
```

The above LDAP information is very specific. You need to know your information to access your LDAP service. To explore and learn about the required LDAP search strings and DNs the tool "LDAP Browser" from LDAPSOFT (http://www.ldapsoft.com) showed to be of great help.

Here is another known ldap configuration for jass.config (thanks to Pavel Fibich):

```
          org.jboss.security.auth.spi.LdapExtLoginModule REQUIRED
            java.naming.provider.url="ldap://your.ldap.server.cz:389"
            baseCtxDN="ou=People,dc=perun,dc=cesnet,dc=cz"
            rolesCtxDN="ou=People,dc=perun,dc=cesnet,dc=cz"
            bindDN="perunUserId=12345,ou=People,dc=perun,dc=cesnet,dc=cz"
            bindCredential="PASSWORD_FOR_SERVICE_ACCOUNT_LINE_ABOVE"
            baseFilter="(&(memberOfPerunVo=21)(login;x-ns-einfra={0}))"
            roleFilter="(&(memberOfPerunVo=21)(login;x-ns-einfra={0}))"
            roleAttributeID="memberOf"
            allowEmptyPasswords="false";
```

## Troubleshooting

If the authentication doesn't work, check first `auth` logs. If that doesn't help, check that your `values.yaml` file produced the correct configuration.

There should be `auth-jaas-conf-path` defined in the auth configuration:

```bash
bash get-secret.bash auth
```

Check `jaas.config`:

```bash
bash get-secret.bash auth jaas.config
```

Check that these files are visible in the container:

```bash
kubectl exec deployment/auth -- cat conf/chipster.yaml
kubectl exec deployment/auth -- cat conf/jaas.config
```
