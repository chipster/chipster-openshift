#!/bin/bash

job="$1"

escaped=$(cat ../chipster-private/confs/jenkins/subproject_options | sed '$!s@$@\\@g')

cat jenkins/jobs/$job.xml \
	| sed "s@{{SUBPROJECT_OPTIONS}}@$escaped@g" \
	> job.tmp

curl -X POST $JENKINS_HOST/job/$job/config.xml --user $JENKINS_USER:$JENKINS_TOKEN --data-binary "@job.tmp"

rm -f job.tmp