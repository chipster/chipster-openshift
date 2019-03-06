#!/bin/bash

set -e

source jenkins/jenkins-utils.bash

job="$1"

check_jenkins_login

if [ -z "$job" ]; then
  echo "Usage: bash upload-jenkins-job.bash JOB_NAME"
  echo ""
  echo "Upload the local .xml jenkins job to the server. Private content can be added from " 
  echo "the private repository by using {{...}} notation in the xml file."
  echo ""
  exit 1
fi

job_path="jenkins/jobs/$job.xml"

if [ ! -f  $job_path ]; then
  echo "Job file not found: $job_path"
  exit 1
fi

# get some parameter options from the private repository
escaped=$(cat ../chipster-private/confs/jenkins/subproject_options | sed '$!s@$@\\@g')

cat $job_path \
	| sed "s@{{SUBPROJECT_OPTIONS}}@$escaped@g" \
	> job.tmp

curl -X POST $JENKINS_HOST/job/$job/config.xml --user $JENKINS_USER:$JENKINS_TOKEN --data-binary "@job.tmp"

rm -f job.tmp