for d in auth service-locator session-db file-broker scheduler comp session-worker type-service web-server toolbox; do oc deploy $d --latest; done
