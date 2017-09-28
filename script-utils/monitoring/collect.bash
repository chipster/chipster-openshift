# exit on error
set -e
# exit on uninitialized variable
set -u

influxdb="http://influxdb:8086"
token_file="/tmp/chipster_monitoring_token"

if [ -f $token_file ]; then
    token=$(cat $token_file)
    # remove the token file. If anything goes wrong, get a new token next time
    rm $token_file;
else
	echo "authenticate"
	if ! auth_resp=$(curl -s -S --fail -X POST http://auth:8002/tokens?pretty -u monitoring:$password); then
		echo authentication error, auth response "$auth_resp"
		exit 1
	fi
		
	if ! token=$(echo "$auth_resp" | jq .tokenKey -r ); then
		echo token parsing failed: $token
	fi
	
	# if var uninitialized
	if [[ ! -v token ]]; then	
		echo token not set
		exit 1
	fi
fi

#echo token $token

t0=$(date +%s%N)

if ! status=$(curl -s -S --fail localhost:$admin_port/admin/status?pretty -u token:${token}); then
	echo status query failed: "$status"
	exit 1
fi

post_data=""

# Use here-string in the end of the loop to provide the data for the while loop to avoid a subshell.
# Otherwise we can't modify the $post_data in the loop
while read key; do

	# use .["key"] notation to tolerate special characters like "="
    value=$(echo "$status" | jq '.["'"$key"'"]')

    db_key=$(echo ${key},role=${role},id=${HOSTNAME})
            
    post_data="${post_data}${db_key} value=$value $t0"$'\n'

done <<< "$(echo "$status" | jq -r 'keys[]')"

echo "** save $post_data"

curl -s -S --fail -XPOST "${influxdb}/write?db=db" --data-binary "$post_data"

# success, save the token for the next round
echo $token > $token_file 