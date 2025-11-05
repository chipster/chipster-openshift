#!/bin/bash

set -e

source $(dirname "$0")/env.bash

stop_and_remove_all

mkdir -p db-data storage conf security podman-graphroot tools-bin/$TOOLS_BIN_VERSION

if [ -z $postgres_password ]; then
    echo "generate new database password"
    postgres_password=$(openssl rand -base64 24)
fi

# generate chipster configuration

cat > $HOST_DIR/conf/chipster.yaml << EOF

db-url-auth: jdbc:postgresql://host.containers.internal:5432/auth_db
db-url-session-db: jdbc:postgresql://host.containers.internal:5432/session_db_db
db-url-job-history: jdbc:postgresql://host.containers.internal:5432/job_history_db

db-user: postgres
db-pass-auth: $postgres_password
db-pass-session-db: $postgres_password
db-pass-job-history: $postgres_password

# podman containers can call other with this hostname
variable-int-ip: host.containers.internal

# browser can call APIs with this hostname
variable-ext-ip: localhost

# use built-in scripts for podman to start jobs
scheduler-bash-script-dir-in-jar: bash-job-scheduler/podman

toolbox-runtime-tools-bin-name: $TOOLS_BIN_VERSION

scheduler-bash-image-repository: $IMAGE_REPOSITORY
scheduler-bash-image-tag: $IMAGE_TAG
scheduler-bash-tools-bin-host-mount-path: $HOST_DIR/tools-bin

# generate key for signing authentication tokens
# without this a new key is generated on every restart resulting ugly error messages in browser
jws-private-key-auth: |
$(openssl ecparam -genkey -name secp521r1 -noout | sed 's/^/  /g')

# generate a proper password to hide a warning
auth-monitoring-password: $(openssl rand -base64 24)
EOF

# generate proper passwords for each component
# these are not really needed on a disconnected server, but this hides some warnings 
for component in auth session-db service-locator scheduler file-broker session-worker web-server toolbox job-history backup file-storage s3-storage type-service; do
    echo "service-password-$component: $(openssl rand -base64 24)" >> $HOST_DIR/conf/chipster.yaml
done

# generate basic user accounts
cat > $HOST_DIR/security/users << EOF
chipster:chipster
admin:admin
EOF

start_postgres

# In the container, files are owned by postgres:root. The container root user and group are 
# mapped to the current user and group on the host. Add access rights for the group to be able to 
# access the files on the host. This keeps Postgres happy, because we don't change the file 
# owners.
#
# chmod -R complains about permissions, but bash loop seems to work

echo "fix postgres permissions"
podman exec postgres bash -c 'for f in $(find /var/lib/postgresql/data); do chmod g+rwX $f; done'

echo "create databases (if not created already)"

podman run --rm --network podman -e PGPASSWORD=$postgres_password ${IMAGE_REPO}backup:$IMAGE_TAG createdb -h host.containers.internal -U postgres auth_db || true
podman run --rm --network podman -e PGPASSWORD=$postgres_password ${IMAGE_REPO}backup:$IMAGE_TAG createdb -h host.containers.internal -U postgres session_db_db || true
podman run --rm --network podman -e PGPASSWORD=$postgres_password ${IMAGE_REPO}backup:$IMAGE_TAG createdb -h host.containers.internal -U postgres job_history_db || true

