script_path=$1

if [ -z $script_path ]; then
  echo "Usage: bash for-each-comp.bash SCRIPT"
  exit 1
fi

for pod in $(oc get pod | grep comp | grep Running | cut -d " " -f 1 ); do 
  oc rsh -c comp $pod bash -c "$(cat $1)"
done
