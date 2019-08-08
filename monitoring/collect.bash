# exit on error
set -e
# exit on uninitialized variable
set -u

influxdb="http://influxdb:8086"
token_file="/tmp/chipster_monitoring_token"
response_body_file="/tmp/chipster_monitoring_response_body"

# print http code, reponse body and exit on HTTP error
function http_request {

  method="$1"
  url="$2"
  # optional arguments, default to empty value
  credentials="${3-}"
  data="${4-}"

  rm -f $response_body_file  
  
  cmd="curl -s -S -X "$method" "$url" -w '%{http_code}' -o $response_body_file"
  
  if [[ $credentials ]]; then
    cmd="$cmd -u $credentials"
  fi
  
  if [[ $data ]]; then
    cmd="$cmd --data-binary \"$data\""
  fi
  
  http_code=$(bash -c "$cmd")
  
  if [ $http_code -gt 199 -a $http_code -lt 300 ]; then
    cat $response_body_file
  else
    echo "HTTP error $http_code ($url)" >&2
    cat $response_body_file >&2
    exit 1
  fi
}

if [ -f $token_file ]; then
  token=$(cat $token_file)
  # remove the token file. If anything goes wrong, get a new token next time
  rm $token_file;
else
  echo "authenticate" 
  token=$(http_request POST http://auth/tokens?pretty monitoring:$password) 
fi

#echo token $token

t0=$(date +%s%N)

status=$(http_request GET localhost:$admin_port/admin/status?pretty token:${token})

# status request was successful, save the token for the next round
echo $token > $token_file

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

http_request POST "${influxdb}/write?db=db" "" "$post_data"
