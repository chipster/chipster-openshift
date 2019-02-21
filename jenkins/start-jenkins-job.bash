#!/bin/bash

job="$1"

curl -X POST $JENKINS_HOST/job/$job/build --user $JENKINS_USER:$JENKINS_TOKEN

echo "console output available in"
echo "curl $JENKINS_HOST/job/$job/lastBuild/consoleText --user $JENKINS_USER:$JENKINS_TOKEN"
echo "$JENKINS_HOST/job/deploy-chipster/lastBuild/console"