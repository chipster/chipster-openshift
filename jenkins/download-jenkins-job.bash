#!/bin/bash

source jenkins/jenkins-utils.bash

job="$1"

check_jenkins_login

if [ -z "$job" ]; then
  echo "Usage: bash download-jenkins-job.bash JOB_NAME"
  exit 1
fi

out_file="jenkins/jobs/$job.xml"

if [ -n jenkins/jobs/$job.xml ]; then
  if cat jenkins/jobs/$job.xml | grep "{{"; then
    out_file="${out_file}_DO_NOT_COMMIT"
    echo "The local job file contains private variables. The remote file is saved to $out_file. Manual merge is needed!"
  fi  
fi 

curl -s -X GET $JENKINS_HOST/job/$job/config.xml --user $JENKINS_USER:$JENKINS_TOKEN > "$out_file"
