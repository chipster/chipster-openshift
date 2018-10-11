domain=$1
username=$2
password=$3

duration=10

function print {
	echo "$@"
	echo "$("$@")" | grep -e "Requests per second" -e "Failed requests" 
}

token=$(curl -s -X POST http://auth-$domain/tokens -u $username:$password | jq ".tokenKey" --raw-output)

print ab -r -t $duration -c 100 http://$domain/

print ab -r -t $duration -c 100 http://service-locator-$domain/services

print ab -r -t $duration -c 10 http://toolbox-$domain/tools/samtools-index.R

print ab -r -t $duration -c 2 -m POST -A token:$token http://auth-$domain/tokens

print ab -r -t $duration -c 2 -A token:$token http://session-db-$domain/sessions
