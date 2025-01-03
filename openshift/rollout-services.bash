# Redeploy manually all services having our code.
# Most often the deployemnt happens after new code is pusehd to the repository. GitHub webhooks
# can be configured to handle that automatically, but for some infrequent maintenance tasks
# running this manually is fine
   
for d in auth service-locator session-db file-broker scheduler session-worker type-service web-server toolbox backup job-history; do 
	echo $d
	oc rollout cancel dc/$d
done

for d in auth service-locator session-db file-broker scheduler session-worker type-service web-server toolbox backup job-history; do 
	echo $d
	oc rollout latest $d
done

# is there a better way?

# - alternative 1: scale to zero and then back in the yaml in web ui
# - alternative 2: delete pods
# - alternative 3: delete stateful set in web and recreate using deploy_servers.bash
#json=$(oc get sts file-storage$subproject_postfix -o json); oc delete sts file-storage$subproject_postfix; echo "$json" | oc apply -f -
