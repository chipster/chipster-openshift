dbPassAuth="$(kubectl get secret passwords -o json | jq '.data."values.yaml"' -r | base64 -d | yq r - databases.auth.password)"
dbPassSessionDb="$(kubectl get secret passwords -o json | jq '.data."values.yaml"' -r | base64 -d | yq r - databases.sessionDb.password)"
dbPassJobHistory="$(kubectl get secret passwords -o json | jq '.data."values.yaml"' -r | base64 -d | yq r - databases.jobHistory.password)"

helm install auth stable/postgresql --set postgresqlDatabase=auth_db --set postgresqlPassword="$dbPassAuth"
helm install session-db stable/postgresql --set postgresqlDatabase=session_db_db --set postgresqlPassword="$dbPassSessionDb"
helm install job-history stable/postgresql --set postgresqlDatabase=job_history_db --set postgresqlPassword="$dbPassJobHistory"