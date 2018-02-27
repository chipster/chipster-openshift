# Redeploy manually all services having our code.
# Most often the deployemnt happens after new code is pusehd to the repository. GitHub webhooks
# can be configured to handle that automatically, but for some infrequent maintenance tasks
# running this manually is fine, e.g. after running create-secrets.bash
   
for d in auth service-locator session-db file-broker scheduler comp session-worker type-service web-server toolbox haka; do 
	oc rollout latest $d
done
