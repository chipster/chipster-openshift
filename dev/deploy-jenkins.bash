oc project chipster-jenkins

oc new-build --name chipster-jenkins -D - < dockerfiles/chipster-jenkins/Dockerfile
oc logs -f bc/chipster-jenkins

#oc delete route jenkins; oc delete dc jenkins; oc delete sa jenkins; oc delete service jenkins; oc delete service jenkins-jnlp

oc new-app --template=jenkins-ephemeral --name jenkins \
-p NAMESPACE=chipster-jenkins \
-p DISABLE_ADMINISTRATIVE_MONITORS=true \
-p JENKINS_IMAGE_STREAM_TAG=chipster-jenkins:latest
 
 firewall="$(cat ../chipster-private/confs/rahti-int/admin-ip-whitelist)"
 oc get -o json route jenkins | jq ".metadata.annotations.\"haproxy.router.openshift.io/ip_whitelist\" = \"$firewall\"" | oc apply -f -
 
 # go to jenkins and click your username on the top right corner
 # store your Jenkins User ID to env "JENKINS_USER" 
 # click "Configure" and click "Add new token" and "Genereate". Save the token to env "JENKINS_TOKEN"
 
curl -X POST --user $JENKINS_USER:$JENKINS_TOKEN -d '<jenkins><install plugin="rebuild@latest" /></jenkins>' --header 'Content-Type: text/xml' https://jenkins-chipster-jenkins.rahtiapp.fi/pluginManager/installNecessaryPlugins

bash dev/add_jenkins_credential.bash FIREWALL "$firewall"  
