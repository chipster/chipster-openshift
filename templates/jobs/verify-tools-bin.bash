set -e

cd /mnt/tools

work_dir="/mnt/temp"

file_list_path=$work_dir/files.txt
checksum_path=$work_dir/files.md5

pwd
du -sh .

find . -type f | sort > $file_list_path

echo "count files"

cat $file_list_path | wc -l

echo "calculate checksums"

date

while read file; do
  echo "$file"
  md5sum "$file" >> $checksum_path
done <$file_list_path

echo "done"

date

sleep inf