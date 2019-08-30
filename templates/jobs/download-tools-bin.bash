set -e

cd /mnt/tools

export temp="/mnt/temp"
export url="https://object.pouta.csc.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/${TOOLS_BIN_VERSION}/parts"

# Kill other tasks after first error: "--halt 2" in this old 2014 version 
# of parallel, equals "--halt now,fail=1" in newer versions.
#
# Using "set -o pipefail" and "curl --fail" to  fail on curl errors too 
# and not only based on the exit code of the last "tar" command. Although 
# tar is quite good in noticing errors too.
#
# Downlaod packages to local temp file before extraction. We can't pipe directly
# from the curl to lz4 and targ, becausew when the files
# are small, it would take too much time to create all files in pipe's 64k buffer
# causing the server to timeout the idle connection. 
  
function download_file {
    file="$1"
	set -o pipefail
	size=$(curl -sI $url/$file | grep -i Content-Length | cut -d ' ' -f 2 | tr -d '\r')
	retries=10
	fail=0
	for i in $(seq 1 $retries); do
		echo "$url/$file $size, try $i" 
		get --no-verbose --tries 5 $url/$file -O $temp/$file && cat $temp/$file | lz4 -d | tar -x \
			&& rm $temp/$file \
			&& break || fail="$?"
	done
	
	if [ "$fail" != 0 ]; then
		echo "echo downloading $url/$file failed $retries times, give up"
		exit $fail
	else
		echo $url/$file $size, try $i completed
	fi
}

export -f download_file

# delete old download temp files
rm -f $temp/*
          
curl -s $url/files.txt | grep lz4$ | parallel --ungroup -j 8 --halt 2 "download_file {}"