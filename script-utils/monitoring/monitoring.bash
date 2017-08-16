while true; do

	influxdb="http://influxdb:8086"
	auth_resp=$(curl -s -S -X POST http://auth:8002/tokens?pretty -u monitoring:$password)
	token=$(echo "$auth_resp" | grep tokenKey | cut -d '"' -f 4 )
	
	#echo token $token
	
	if [ -z "$token" ]; then	
		echo authentication error, auth response "$auth_resp"
	fi

	status=$(curl -s --fail localhost:$admin_port/admin/status?pretty -u token:${token})
	curl_exit_code=$?
	
	if test "$curl_exit_code" != "0"; then	
		echo status query failed: "$status"
	fi
	
	echo "$status" | jq -r 'keys[]' | while read key; do

	    value=$(echo "$status" | jq ."$key")
	
	    db_key=$(echo ${key},role=${role},id=${HOSTNAME})
	
	    echo "** save ${db_key} $value"
	    curl -s -S -XPOST "${influxdb}/write?db=db" --data-binary "${db_key} value=$value"
	done

	sleep 10
done
