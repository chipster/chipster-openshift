#!/bin/bash

source jenkins/jenkins-utils.bash

job="$1"

check_jenkins_login

if [ -z "$job" ]; then
  echo "Usage: bash create-jenkins-job.bash JOB_NAME"
  exit 1
fi

job_path="jenkins/jobs/$job.xml"

if [ ! -f  $job_path ]; then
  echo "Job file not found: $job_path"
  exit 1
fi

curl -X POST $JENKINS_HOST/createItem?name="$job" --user $JENKINS_USER:$JENKINS_TOKEN --data-binary "@$job_path" -H "Content-Type:text/xml"
