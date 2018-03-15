#!/bin/bash

PROJECT=$1
DOMAIN=$2

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
			echo url-ext-$service: $proto$PROJECT.$DOMAIN
		else			
			echo url-ext-$service: $proto$service-$PROJECT.$DOMAIN
		fi
	fi
done < ../chipster-web-server/conf/chipster-defaults.yaml

# admin route urls
while read line; do
	if [[ $line == url-admin-ext-* ]]; then
		service=$(echo $line | cut -d : -f 1 | sed s/url-admin-ext-//)
		default_url=$(echo $line | cut -d " " -f 2)
		proto=$(echo $default_url | cut -d { -f 1)
		
		if [[ $proto == "http://" ]]; then
			proto="https://"
		fi
		
		echo url-admin-ext-$service: $proto$service-admin-$PROJECT.$DOMAIN		
	fi
done < ../chipster-web-server/conf/chipster-defaults.yaml

# m2m urls
while read line; do
	if [[ $line == url-m2m-int-* ]]; then
		service=$(echo $line | cut -d : -f 1 | sed s/url-m2m-int-//)
		default_url=$(echo $line | cut -d " " -f 2)
		proto=$(echo $default_url | cut -d { -f 1)
		
		echo url-m2m-int-$service: $proto$service-m2m
	fi
done < ../chipster-web-server/conf/chipster-defaults.yaml

# internal service urls
while read line; do
	if [[ $line == url-int-* ]]; then
		service=$(echo $line | cut -d : -f 1 | sed s/url-int-//)
		default_url=$(echo $line | cut -d " " -f 2)
		proto=$(echo $default_url | cut -d { -f 1)
		
		echo url-int-$service: $proto$service
	fi
done < ../chipster-web-server/conf/chipster-defaults.yaml
