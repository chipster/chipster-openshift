influxdb="http://influxdb:8086"
port_env=$(echo $role | tr '[:lower:]' '[:upper:]')_SERVICE_PORT
port=${!port_env}
auth_resp=$(curl -s -S -X POST http://auth:8002/tokens?pretty -u admin:$password)
echo auth response "$auth_resp"
token=$(echo "$auth_resp" | grep tokenKey | cut -d '"' -f 4 )
echo token $token
while true; do

  status=$(curl  -s -S localhost:$port/admin/status?pretty -u token:${token} | grep ":")

  echo status "$status"

   echo "$status" | while read line; do

    key=$(echo "$line" | grep : | cut -d '"' -f 2)
    # xargs to trim whitespace
    value=$(echo "$line" | grep : | cut -d ':' -f 2 | cut -d ',' -f 1 | xargs)

    # if not a number, add quotes to store as a string
    if [[ $value != *[[:digit:]]* ]]; then
     value="\"$value\""
    fi

    db_key=$(echo ${key},role=${role},id=${HOSTNAME})

    echo "** save ${db_key} $value"
    curl -XPOST "${influxdb}/write?db=db" --data-binary "${db_key} value=$value"
	done

	sleep 10
done
