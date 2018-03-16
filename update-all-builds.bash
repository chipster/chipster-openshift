for f in dockerfiles/*; do
  name=$(basename $f)
  bash update-dockerfile.bash $name
  oc start-build $name
done