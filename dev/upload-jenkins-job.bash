#!/bin/bash

job="$1"

curl -X POST https://jenkins-chipster-jenkins.rahtiapp.fi/job/$job/config.xml --user $JENKINS_USER:$JENKINS_TOKEN --data-binary "@dev/jenkins-jobs/$job.xml"
