#!/bin/bash

PROJECT=$1
DOMAIN=$2
subproject=$3

if [ -z $subproject ]; then
  subproject_postfix=""
else
  subproject_postfix="-$subproject"
fi

# external route urls
while read line; do
	if [[ $line == url-ext-* ]]; then
		service=$(echo $line | cut -d : -f 1 | sed s/url-ext-//)
		default_url=$(echo $line | cut -d " " -f 2)
		proto=$(echo $default_url | cut -d { -f 1)
		
		if [[ $proto == "http://" ]]; then
			proto="https://"
		fi
		
		if [[ $proto == "ws://" ]]; then
			proto="wss://"
		fi
		
		if [[ $service == web-server ]]; then
			if [ -z $subproject ]; then
				echo url-ext-$service: $proto$PROJECT.$DOMAIN
			else
				echo url-ext-$service: $proto$subproject-$PROJECT.$DOMAIN
			fi
		else			
			echo url-ext-$service: $proto$service$subproject_postfix-$PROJECT.$DOMAIN
		fi
	fi
done < ../chipster-web-server/src/main/resources/chipster-defaults.yaml

# admin route urls
while read line; do
	if [[ $line == url-admin-ext-* ]]; then
		service=$(echo $line | cut -d : -f 1 | sed s/url-admin-ext-//)
		default_url=$(echo $line | cut -d " " -f 2)
		proto=$(echo $default_url | cut -d { -f 1)
		
		if [[ $proto == "http://" ]]; then
			proto="https://"
		fi
		
		echo url-admin-ext-$service: $proto$service$subproject_postfix-admin-$PROJECT.$DOMAIN		
	fi
done < ../chipster-web-server/src/main/resources/chipster-defaults.yaml

# internal service urls
while read line; do
	if [[ $line == url-int-* ]]; then
		service=$(echo $line | cut -d : -f 1 | sed s/url-int-//)
		default_url=$(echo $line | cut -d " " -f 2)
		proto=$(echo $default_url | cut -d { -f 1)
		
		echo url-int-$service: $proto$service$subproject_postfix
	fi
done < ../chipster-web-server/src/main/resources/chipster-defaults.yaml
