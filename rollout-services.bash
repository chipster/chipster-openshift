# Redeploy manually all services having our code.
# Most often the deployemnt happens after new code is pusehd to the repository. GitHub webhooks
# can be configured to handle that automatically, but for some infrequent maintenance tasks
# running this manually is fine, e.g. after running create-secrets.bash

subproject="$1"

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
fi
   
for d in auth service-locator session-db file-broker scheduler comp session-worker type-service web-server toolbox backup job-history; do 
	echo $d
	oc rollout cancel dc/$d$subproject_postfix
done

for d in auth service-locator session-db file-broker scheduler comp session-worker type-service web-server toolbox backup job-history; do 
	echo $d
	oc rollout latest $d$subproject_postfix
done

# is there a better way?

# - alternative 1: scale to zero and then back in the yaml in web ui
# - alternative 2: delete pods
# - alternative 3: delete stateful set in web and recreate using deploy_servers.bash
#json=$(oc get sts file-storage$subproject_postfix -o json); oc delete sts file-storage$subproject_postfix; echo "$json" | oc apply -f -
