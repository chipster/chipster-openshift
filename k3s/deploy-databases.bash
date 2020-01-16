dbPassAuth="$(sudo kubectl get secret passwords -o json | jq .data.passwords -r | base64 -d | yq r - databases.auth.password)"
dbPassSessionDb="$(sudo kubectl get secret passwords -o json | jq .data.passwords -r | base64 -d | yq r - databases.sessionDb.password)"
dbPassJobHistory="$(sudo kubectl get secret passwords -o json | jq .data.passwords -r | base64 -d | yq r - databases.jobHistory.password)"

sudo helm install auth stable/postgresql --set postgresqlDatabase=auth_db --set postgresqlPassword="$dbPassAuth"
sudo helm install session-db stable/postgresql --set postgresqlDatabase=session_db_db --set postgresqlPassword="$dbPassSessionDb"
sudo helm install job-history stable/postgresql --set postgresqlDatabase=job_history_db --set postgresqlPassword="$dbPassJobHistory"