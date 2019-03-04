oc project chipster-jenkins

oc new-build --name chipster-jenkins -D - < dockerfiles/chipster-jenkins/Dockerfile
oc logs -f bc/chipster-jenkins

#oc delete route jenkins; oc delete dc jenkins; oc delete sa jenkins; oc delete service jenkins; oc delete service jenkins-jnlp

oc new-app --template=jenkins-ephemeral --name jenkins \
-p NAMESPACE=chipster-jenkins \
-p DISABLE_ADMINISTRATIVE_MONITORS=true \
-p JENKINS_IMAGE_STREAM_TAG=chipster-jenkins:latest

# convert an ephemeral jenkins to a persistent installation, because the persistent jenkins template times out
oc volume dc/jenkins --remove --name jenkins-data
sleep 5
oc volume dc/jenkins --add --name jenkins-data --type=pvc --claim-name jenkins-data --claim-size 1Gi --mount-path /var/lib/jenkins
 
 deploy_conf="$(cat ../chipster-private/confs/chipster-all/deploy.yaml)"
 firewall="$(echo "$deploy_conf" | yq r - ip-whitelist-admin)"
 
 oc get -o json route jenkins | jq ".metadata.annotations.\"haproxy.router.openshift.io/ip_whitelist\" = \"$firewall\"" | oc apply -f -
 
 export JENKINS_HOST="https://$(oc get -o json route jenkins | jq .spec.host -r)"
 
 # go to jenkins and click your username on the top right corner
 # store your Jenkins User ID to env "JENKINS_USER" 
 # click "Configure" and click "Add new token" and "Generate". Save the token to env "JENKINS_TOKEN"
 
curl -X POST --user $JENKINS_USER:$JENKINS_TOKEN -d '<jenkins><install plugin="rebuild@latest" /></jenkins>' \
  --header 'Content-Type: text/xml' \
  https://jenkins-chipster-jenkins.rahtiapp.fi/pluginManager/installNecessaryPlugins
  
curl -X POST --user $JENKINS_USER:$JENKINS_TOKEN -d '<jenkins><install plugin="uno-choice@latest" /></jenkins>' \
  --header 'Content-Type: text/xml' \
  https://jenkins-chipster-jenkins.rahtiapp.fi/pluginManager/installNecessaryPlugins
  

# store private confs as Jenkins managed files
bash jenkins/add-jenkins-file.bash DEPLOY_CONF --string "$deploy_conf"
bash jenkins/add-jenkins-file.bash OPENSHIFT_PROJECT --string "$(cat ../chipster-private/confs/jenkins/openshift_project)"
bash jenkins/add-jenkins-file.bash CHIPSTER_DEV_PATCH --string "$(cat ../chipster-private/confs/chipster-dev.rahtiapp.fi/chipster-template-patch.bash)"

# store secrets as Jenkins credentials 
bash jenkins/add-jenkins-credential.bash USERS_CONF "$(cat ../chipster-private/confs/chipster-all/users)"

# use create-namespaces.bash to create a project where the Chipster is deployed
  
