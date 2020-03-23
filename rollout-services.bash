# Redeploy manually all services having our code.
# Most often the deployemnt happens after new code is pusehd to the repository. GitHub webhooks
# can be configured to handle that automatically, but for some infrequent maintenance tasks
# running this manually is fine, e.g. after running create-secrets.bash
   
for d in auth service-locator session-db file-broker scheduler comp session-worker type-service web-server toolbox backup job-history; do 
	echo $d
	oc rollout cancel dc/$d
done

for d in auth service-locator session-db file-broker scheduler comp session-worker type-service web-server toolbox backup job-history; do 
	echo $d
	oc rollout latest $d
done

# is there a better way?
json=$(oc get sts file-storage -o json); oc delete sts file-storage; echo "$json" | oc apply -f -