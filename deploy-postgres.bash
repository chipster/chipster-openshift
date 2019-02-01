#!/bin/bash

set -e

source scripts/utils.bash

oc new-app centos/postgresql-95-centos7 --name auth-postgres \
    -e POSTGRESQL_USER=user \
    -e POSTGRESQL_PASSWORD=$(get_db_password auth) \
    -e POSTGRESQL_DATABASE=auth_db
    
oc new-app centos/postgresql-95-centos7 --name session-db-postgres \
    -e POSTGRESQL_USER=user \
    -e POSTGRESQL_PASSWORD=$(get_db_password session-db) \
    -e POSTGRESQL_DATABASE=session_db_db
        
oc new-app centos/postgresql-95-centos7 --name job-history-postgres \
    -e POSTGRESQL_USER=user \
    -e POSTGRESQL_PASSWORD=$(get_db_password job-history) \
    -e POSTGRESQL_DATABASE=job_history_db
    

oc volume dc/auth-postgres --remove --name auth-postgres-volume-1
oc volume dc/session-db-postgres --remove --name session-db-postgres-volume-1
oc volume dc/job-history-postgres --remove --name job-history-postgres-volume-1
sleep 5
oc volume dc/auth-postgres        --add --name postgres-data --type=pvc --claim-name auth-postgres-data        --mount-path /var/lib/pgsql/data
oc volume dc/session-db-postgres  --add --name postgres-data --type=pvc --claim-name session-db-postgres-data  --mount-path /var/lib/pgsql/data
oc volume dc/job-history-postgres --add --name postgres-data --type=pvc --claim-name job-history-postgres-data --mount-path /var/lib/pgsql/data

oc rsh dc/auth-postgres        bash -c "psql -c 'alter system set synchronous_commit = "off"'"
oc rsh dc/session-db-postgres  bash -c "psql -c 'alter system set synchronous_commit = "off"'"
oc rsh dc/job-history-postgres bash -c "psql -c 'alter system set synchronous_commit = "off"'"

oc rollout latest auth-postgres
oc rollout latest session-db-postgres
oc rollout latest job-history-postgres
