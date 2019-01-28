#!/bin/bash

job="$1"

curl -X POST https://jenkins-chipster-jenkins.rahtiapp.fi/job/$job/build --user $JENKINS_USER:$JENKINS_TOKEN