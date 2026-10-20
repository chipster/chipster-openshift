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

# convert json to influxdb request
#
# The field value has to be formatted according to its type. Numbers and
# booleans are written as such, everything else as a quoted string, because
# InfluxDB would try to parse a bare word like "v4.21.5" as a boolean and
# reject the whole batch. tojson also escapes quotes and newlines, which would
# otherwise split one metric into several unparseable lines.
#
# Null values are skipped, because InfluxDB has no null.
post_data="$(echo "$status" | jq -r \
  --arg role "${role}" \
  --arg id "${HOSTNAME}" \
  --arg t0 "${t0}" '
  to_entries
  | map(select(.value != null))
  | map("\(.key),role=\($role),id=\($id) value=" + (
      if (.value | type) == "number" or (.value | type) == "boolean"
      then (.value | tostring)
      else (.value | tostring | tojson)
      end) + " \($t0)")
  | .[]')"

echo "** save $post_data"

http_request POST "${influxdb}/write?db=db" "writer:${influxdb_password-}" "$post_data"
