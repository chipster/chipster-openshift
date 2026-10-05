#!/bin/bash

set -e

source $(dirname "$0")/env.bash

if ! podman images | tr -s ' ' | cut -d " " -f 2 | grep $IMAGE_TAG > /dev/null; then
    echo "Error: container image version not found. "
    echo "Version configured: $IMAGE_TAG (in $BASH_SOURCE)"
    echo "Version available: (in 'podman images'):"
    podman images | tr -s ' ' | cut -d " " -f 2 | sort | uniq
    exit 1
fi

if ! [ -d $HOST_DIR/tools-bin/$TOOLS_BIN_VERSION ]; then
    echo "Error: tools-bin directory not found."
    echo "Version configured: $TOOLS_BIN_VERSION (in $BASH_SOURCE)"
    echo "Versions available (in $HOST_DIR/tools-bin):"
    ls $HOST_DIR/tools-bin
    exit 1
fi

stop_and_remove_all

mkdir -p $HOST_DIR/{db-data,storage,conf,security,podman-graphroot}

if [ -z $postgres_password ]; then
    echo "generate new database password"
    postgres_password=$(openssl rand -base64 24)
fi

# calculate how many jobs slots can run at the same time
ram="$(free -g | grep Mem: | awk '{print $2}')"
slots="$(( (ram - 7) / 8))"
slots="$((slots == 0 ? 1 : slots))"

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

scheduler-bash-max-slots: "$slots"
scheduler-max-scheduled-and-running-slots-per-user: "$slots"

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

# user accounts
# auth refuses to start when a password is blank, the same as the username or one of the other
# well-known default passwords (these accounts used to have the username as the password), so
# replace those with generated passwords and keep everything else in an existing file: other
# passwords, accounts added by hand, expiration dates and comments
users_file=$HOST_DIR/security/users
touch $users_file

# the same list as UsersFile.DEFAULT_PASSWORDS in chipster-web-server
default_passwords="chipster admin example_session_owner support_session_owner clientPassword client2Password monitoring"

new_users_file=$(mktemp)
trap 'rm -f "$new_users_file"' EXIT
awk -F : -v OFS=: -v defaults="$default_passwords" '
    BEGIN { split(defaults, list, " "); for (i in list) is_default[list[i]] = 1 }
    # auth reads the file with String.lines(), which accepts CRLF line endings
    { sub(/\r$/, "") }
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { print; next }
    {
        # like UsersFile.parseLine() and isDefaultPassword() in chipster-web-server: the username is
        # trimmed, the password is compared as it is, except that a whitespace-only password is blank
        username = $1
        sub(/^[[:space:]]+/, "", username)
        sub(/[[:space:]]+$/, "", username)
        stripped_password = $2
        gsub(/[[:space:]]/, "", stripped_password)
        if (stripped_password == "" || $2 == username || ($2 in is_default)) {
            command = "openssl rand -base64 24"
            if ((command | getline $2) <= 0 || close(command) != 0) {
                print "failed to generate a password with openssl" > "/dev/stderr"
                exit 1
            }
        }
        print
    }
' $users_file > $new_users_file
# keep the owner and permissions of the original file
cat $new_users_file > $users_file

# add the basic accounts, if they don't exist yet (the username may have whitespace around it, see above)
for username in chipster admin; do
    if ! grep -q "^[[:space:]]*$username[[:space:]]*:" $users_file; then
        # a separate assignment, so that set -e notices if openssl fails
        password=$(openssl rand -base64 24)
        echo "$username:$password" >> $users_file
    fi
done

echo "user accounts and their passwords are in $users_file"

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

