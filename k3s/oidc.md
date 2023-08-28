# Authenticating Chipster users with OpenID Connect
## Introduction

It's a great idea to use some external authentication source for Chipster users. This way you don't have take care of user accounts, including safe storage and recovery of forgotten passwords. Technically this is implemented with OpenID Connect protocol (OIDC for short). 

This example shows how to configure Google authentication in Chipster. Google authentication is a good target for this example, because anybody can try it. However, using Google accounts will allow anybody (having a Google account) to use your Chipster server, so in practice you want to use more restricted authentication sources or firewalls to limit the access.

## Register the app for Google authentication

Note: Google doens't allow plain IP addresses in OIDC. You need a DNS name for your host to authenticate with Google authentication.

Register you Chipster installation in [Google API Console](https://console.developers.google.com/):

- Select `Credentials` from the menu bar on the left
- Open the `Create credentials` drop down menu and select `OAuth client ID`
- Set `Application type` to `Web application`
- Set some name for your Chipster installation
- Set `Authorised JavaScript origins` to the address of your host: `http://HOST_ADDRESS`
- Set `Authorised redirect URIs` to `http://HOST_ADDRESS/oidc/callback`
- The service will show you a long string called `Client ID`. Copy it. There is a client secret next to it, but Chipster uses so called "implicit flow" by default, where the client secret isn't used.

## Setup OAuth consent screen

Setup an OAuth consent screen. Set at least
- Some application name
- Some support email
- Scopes: `email`, `profile` and `openid`
- Add your HOST_ADDRESS to the list of `Authorised domains`

## Configure OpenID Connect in Chipster

Configure Chipster in `~/values.yaml`. 

```yaml
deployments:
  auth:
    configs:
        auth-oidc-issuer-google: https://accounts.google.com
        auth-oidc-client-id-google: CLIENT_ID
        auth-oidc-logo-google: /assets/html/login/btn_google_signin_light_normal_web@2x.png
        auth-oidc-priority-google: "1"
        auth-oidc-verified-email-only-google: "true"
        auth-oidc-user-id-prefix-google: google
```

It doesn't really matter what the `-google` string is at the end of each configuration key, as long as you use the same string for all configuration items referring to the same authentication method. 
Multiple authentication methods can be configured simply by repeating the same configuration keys but inventing a new postfix for each method.

If you need more special configuration, take a look at all other `auth-oidc-` configuration keys in the file [chipster-defaults.yaml](https://github.com/chipster/chipster-web-server/blob/master/src/main/resources/chipster-defaults.yaml).

Deploy the configuration and restart `auth`.

```bash
bash deploy.bash -f ~/values.yaml
kubectl rollout restart deployment/auth
```

Use the following command to see when new auth has started and the old has disappeared.

```bash
kubectl get pod
```

## Test

Reload the browser and you should see a Google button on the login page.

## Troubleshooting

If the authentication doesn't work, check the auth configuration and auth logs. 

```bash
bash get-secret.bash auth
kubectl logs deployment/auth
```

Also browser's developer console may show some useful information about the failing HTTP requests.

You can also configure `auth` to log all claims (values) that it gets from the authentication service. Add this to the configuration:

```yaml
deployments:
  auth:
    configs:
      auth-oidc-debug: true
```

Deploy, restart and see logs like shown above.

See [Google's OpenID Connect instructions](https://developers.google.com/identity/protocols/oauth2/openid-connect) to find more information about Google's OIDC service.

