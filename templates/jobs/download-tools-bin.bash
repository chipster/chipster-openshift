set -e

cd /mnt/tools

mkdir -p ${TOOLS_BIN_VERSION}
cd ${TOOLS_BIN_VERSION}

export url="https://object.pouta.csc.fi/swift/v1/AUTH_chipcld/chipster-tools-bin/${TOOLS_BIN_VERSION}/parts"

# Kill other tasks after first error: "--halt 2" in this old 2014 version 
# of parallel, equals "--halt now,fail=1" in newer versions.
#
# Using "set -o pipefail" and "curl --fail" to  fail on curl errors too 
# and not only based on the exit code of the last "tar" command. Although 
# tar is quite good in noticing errors too.
#
# Downlaod small lz4 packages to local temp file before extraction. At the 
# moment each lz4 packages contains 1000 small files. When the files
# are small, it takes too much time to create all files in pipe's 64k buffer
# causing the server to timeout the idle connection. The packaging process
# sholud further improved to make sure there are no both large and small files 
# in the same package, because the current logic will fail in that case.
  
function download_file {
    file="$1"
	set -o pipefail
	size=$(curl -sI $url/$file | grep -i Content-Length | cut -d ' ' -f 2 | tr -d '\r')
	retries=10
	fail=0
	for i in $(seq 1 $retries); do
		echo $url/$file $size, try $i
		if [ $size -lt $((5 * 1024 * 1024 * 1024)) ]; then 
			wget --no-verbose --tries 5 $url/$file -O ${file}_tmp && cat ${file}_tmp | lz4 -d | tar -x \
				&& rm ${file}_tmp \
				&& break || fail="$?"
		else
			curl --silent --show-error --fail $url/${file} | lz4 -d | tar -x \
				&& break || fail="$?"
		fi
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
rm -f *_tmp
          
curl -s $url/files.txt | grep lz4$ | parallel --ungroup -j 8 --halt 2 "download_file {}"