#!/bin/bash

job="$1"

curl -X GET https://jenkins-chipster-jenkins.rahtiapp.fi/job/$job/config.xml --user $JENKINS_USER:$JENKINS_TOKEN > "dev/jenkins-jobs/$job.xml"
