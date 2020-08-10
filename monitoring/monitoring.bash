while true; do
	date
	# start in background so that the execution time doesn't affect timing of the next
	timeout 10s bash collect.bash &	
	sleep 10
	# timeout should have terminated the job already, but let's wait just to be sure that we don't create new processes repeatedly and run out of pids
	wait
done
