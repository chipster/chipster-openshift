#!/bin/bash

job="$1"

curl -X POST $JENKINS_HOST/createItem?name="$job" --user $JENKINS_USER:$JENKINS_TOKEN --data-binary "@dev/jenkins-jobs/$job.xml" -H "Content-Type:text/xml"
