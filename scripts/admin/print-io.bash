file="/sys/fs/cgroup/blkio/blkio.throttle.io_service_bytes"

# print container io throughput

function hr () {
    b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,P,E,Y,Z}iB)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        let s++
    done
    echo "$b$d ${S[$s]}"
}

out_line="$(hostname)"

t="10"

file1="$(cat $file)"
sleep $t 
file2="$(cat $file)"

for i in $(seq $(echo "$file1" | wc -l )); do 
  line1=$(echo "$file1"  | head -n $i | tail -1)
  line2=$(echo "$file2"  | head -n $i | tail -1)  

  if [[ $line1 == *Total* ]]; then
    continue
  fi
  key=$(echo $line1 | cut -d " " -f 1,2)
  value1=$(echo $line1 | cut -d " " -f 3)
  value2=$(echo $line2 | cut -d " " -f 3)
  delta=$(($value2 - $value1))
  hr_delta=$(hr $delta)

  if [ $delta -ne "0" ]; then
    out_line="$out_line 	$key $hr_delta/s"
  fi
done

echo $out_line
