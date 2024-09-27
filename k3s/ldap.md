# Authenticating Chipster users with LDAP

## Introduction

Chipster v4 supports LDAP authentication through JAAS configuration just like the old v3.

## Test on command line

It's a good idea to get familiar with LDAP queries manually before doing the same in Chipster configuration. This example uses a command line tool `ldapsearch`.

```bash
ldapsearch -x -H LDAP_SERVER/ -D 'BIND_DN' -W -b 'BASE_DN'
```

- The `LDAP_SERVER` is the address and port of our LDAP server, something like `ldaps://ldap.example.com:636`.
- Your `BIND_DN` is something like: `cn={USERNAME},ou=people,dc=example,dc=com` and basically is your (horribly long) username for the LDAP server.
- `BASE_DN` is the starting point of the search, for example: `ou=people,dc=example,dc=com`. This defines the group of users that you want to allow.

Chipster tries to do a similar LDAP query, when an end-user wants to log in. The `{USERNAME}` here in the BIND_DN is end-user's short username, for example "jsmith". When you run the `ldapsearch` command above, it will ask user's password and then shows the search results, if the authentication was accepted.

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

After adding the values from the `ldapsearch` example, the LdapLoginModule part will look something like the following snippet. Don't replace the `{USERNAME}` this time yourself, because that LdapLoginModule has to replace it with the end-user's username.

```yaml
com.sun.security.auth.module.LdapLoginModule sufficient
userProvider="ldaps://ldap.example.com:636/ou=people,dc=example,dc=com"
authIdentity="cn={USERNAME},ou=people,dc=example,dc=com"
useSSL=true
debug=true;
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

## Configuration example for ActiveDirectory

This [example configuration](https://sourceforge.net/p/chipster/mailman/message/58821377/) was provided by Oliver Heil.

For all, who struggle with ldap login, this is what led me to the configuration:

1. Dumped the whole ldap directory using ldapsearch
   This looks like:

```bash
ldapsearch -E pr=1000/noprompt -x -w password -D user -H
"ldap://ldap.server.com" -b 'OU=OUR-OU,DC=OUR-AD,DC=dkfz-heidelberg,DC=de' | less
```

password,user,ldap.server.com,OUR-OU,OUR-AD need to be specific for your
organisation.

Looking for myself (oheil) in this data I found an entry like:

userPrincipalName: oheil@OUR-AD.dkfz-heidelberg.de

2. a solved question on SO
   <https://stackoverflow.com/questions/36548510/failedloginexception-encountered-when-using-jaas-ldaploginmodule-to-authenticate>

which gave me a new possible configuration im ~/values.yaml :

```yaml
jaas.config: |
  /** Login Configuration for Chipster **/
  Chipster {
    fi.csc.chipster.auth.jaas.SimpleFileLoginModule sufficient passwdFile="security/users";
    com.sun.security.auth.module.LdapLoginModule sufficient
        userProvider="ldap://OUR-AD.DKFZ-HEIDELBERG.DE:389/OU=OUR-OU,DC=OUR-AD,DC=dkfz-heidelberg DC=de"
        authIdentity="{USERNAME}@OUR-AD.dkfz-heidelberg.de"
        userFilter="(&(|(samAccountName={USERNAME})(userPrincipalName={USERNAME})(cn={USERNAME}))(objectClass=user))" 
        useSSL=false
        debug=true;
  };
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
