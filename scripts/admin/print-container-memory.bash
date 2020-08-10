# print container memory values from /sys/fs/cgroup/memory/memory.stat

out_line="$(hostname)"

for key in $(cat /sys/fs/cgroup/memory/memory.stat | cut -d " " -f 1 | grep -v total_); do 
  line=$(cat /sys/fs/cgroup/memory/memory.stat | grep $key)
  value=$(echo $line | cut -d " " -f 2)
  gigas=$(($value / 1024 / 1024 / 1024))
  if [ $gigas -ne "0" ]; then
    out_line="$out_line 	$key ${gigas}g"
  fi
done

echo $out_line
