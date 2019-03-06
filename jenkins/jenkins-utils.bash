#!/bin/bash


function check_jenkins_login {
	if [ -z "$JENKINS_HOST" ] || [ -z "$JENKINS_USER" ] || [ -z "$JENKINS_TOKEN" ]; then
	
	  if [ -z "$JENKINS_HOST" ]; then
	    echo "Variable \$JENKINS_HOST is not set"
	  fi
	
	  if [ -z "$JENKINS_USER" ]; then
	    echo "Variable \$JENKINS_USER is not set"
	  fi
	
	  if [ -z "$JENKINS_TOKEN" ]; then
	    echo "Variable \$JENKINS_TOKEN is not set"
	  fi
	
	  echo ""
	  echo "Three variables must be configured to use Jenkins API"
	  echo ""
	  echo "JENKINS_HOST"
	  echo "  Go to Jenkins project in OpenShfit and find the jenkins Route. For example: "
	  echo "export JENKINS_HOST='https://jenkins-chipster-jenkins.rahtiapp.fi'"
	  echo ""
	  echo "JENKINS_USER"
	  echo "  Go to \$JENKINS_HOST with a browser and log in. Click your username on the top right corner "
	  echo "  and find your Jenkins User ID: "
	  echo "export JENKINS_USER=''"
	  echo ""
	  echo "JENKINS_TOKEN"
	  echo "  Click 'Configure' and click 'Add new token' and 'Generate'. Copy the token token: "
	  echo "export JENKINS_TOKEN=''"
	  echo ""
	  echo "Consider adding these to your ~/.bash_profile"
	  echo ""
	  exit 1
	fi
}