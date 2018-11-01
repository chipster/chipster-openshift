oc new-build --name cli-client https://github.com/chipster/chipster-web-server.git -D - < dockerfiles/cli-client/Dockerfile
oc start-build cli-client --follow


project="$(oc project -q)"

oc process -f templates/cronjobs/benchmark.yaml \
    -p PROJECT="$project" \
    -p USERNAME="benchmark" \
    -p PASSWORD="$password" \
    -p CHIPSTER_URL="https://chipster.rahti-int-app.csc.fi" \
    -p INFLUX_URL="http://influxdb:8086/write?db=db" \
    | oc apply -f -