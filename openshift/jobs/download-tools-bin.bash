set -e

echo "download tools-bin $TOOLS_BIN_VERSION"

cd /mnt/tools

export temp="/mnt/temp"
export url="https://object.pouta.csc.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/${TOOLS_BIN_VERSION}/parts"

# Kill other tasks after first error: "--halt 2" in this old 2014 version 
# of parallel, equals "--halt now,fail=1" in newer versions.
#
# Downlaod packages to local temp file before extraction. We can't pipe directly
# from the curl to lz4 and tar, because when the files
# are small, it would take too much time to create all files in pipe's 64k buffer
# causing the server to timeout the idle connection. 
  
function download_file {
    file="$1"
	size=$(curl -sI $url/$file | grep -i Content-Length | cut -d ' ' -f 2 | tr -d '\r')
	retries=10
	fail=0
	for i in $(seq 1 $retries); do
		echo "$url/$file $size, try $i" 
		wget --no-verbose --tries 5 $url/$file -O $temp/$file || fail="$?"		
		
		if [ $fail != 0 ]; then
			echo "$url/$file $size, try $i download failed"
			continue
		fi

		temp_dir="$temp/$(basename $file .tar.lz4)"

		mkdir $temp_dir
		pushd $temp_dir
		 
		cat $temp/$file | lz4 -d | tar -x || fail="$?"
		if [ $fail != 0 ]; then
			echo "$url/$file $size, try $i extraction failed"
			continue
		fi

		sleep 1

		#echo "verify checksums"
		echo "copy files"
		cat $temp/$file | lz4 -d | tar -t | while read -r extracted_file; do

			# sleep little bit after each file, because glusterfs seems to have problems when too many files
			# are created too fast: https://bugzilla.redhat.com/show_bug.cgi?id=1701736

			mkdir -p "/mnt/tools/$(dirname "$extracted_file")"

			# if symlink
			if [[ -L "$temp_dir/$extracted_file" ]]; then
				cp --no-dereference "$temp_dir/$extracted_file" "/mnt/tools/$extracted_file"
			else
				cp "$temp_dir/$extracted_file" "/mnt/tools/$extracted_file"
			fi
			
			# sleep 0.1

			# # if symlink, just continue to the next file
			# if [[ -L $extracted_file ]]; then
			# 	continue
			# fi

    		# file_checksum="$(md5sum "$extracted_file")"
			# # we have to use regexp in grep to match the end of the line
			# # escape dots, because otherwise those will match any character
			# escaped_file="$(echo $extracted_file | sed 's/\./\\./g')"
			# correct_checksum="$(cat $temp/checksums.md5 | grep " $escaped_file$")"

			# if [ -z "$correct_checksum" ]; then
			# 	echo "file extracted, but checksum not found: $extracted_file"

			# elif [ "$file_checksum" == "$correct_checksum" ]; then
			# 	# nothing to do
			# 	:
			# else
			# 	echo "incorrect checksum of file "$extracted_file" ($file_checksum vs. $correct_checksum)"				
			# 	# next iteration of outer loop
			# 	continue 2
			# fi
		done

		if [ $fail != 0 ]; then
			# try again after incorrect checksum
			continue
		fi

		popd
		rm -rf $temp_dir
		
		rm $temp/$file
		break
	done
	
	if [ "$fail" != 0 ]; then
		echo "echo downloading $url/$file failed $retries times, give up"
		exit $fail
	else
		echo $url/$file $size, try $i completed
	fi
}

export -f download_file

# what creates this?
rm -rf $temp/lost+found

# delete old download temp files
rm -f $temp/*

# wget --no-verbose $url/checksums.md5 -O $temp/checksums.md5

echo "files in $url/files.txt":
curl -s $url/files.txt | wc -l
          
curl -s $url/files.txt | grep lz4$ | parallel --ungroup -j 1 --halt 2 "download_file {}" 2>&1 | tee /mnt/tools/download.log
