#!/bin/bash


source jenkins/jenkins-utils.bash

job="$1"

check_jenkins_login

if [ -z "$job" ]; then
  echo "Usage: bash start-jenkins-job.bash JOB_NAME"
  exit 1
fi

curl -X POST $JENKINS_HOST/job/$job/build --user $JENKINS_USER:$JENKINS_TOKEN

echo "console output available in"
echo "curl $JENKINS_HOST/job/$job/lastBuild/consoleText --user $JENKINS_USER:$JENKINS_TOKEN"
echo "$JENKINS_HOST/job/deploy-chipster/lastBuild/console"