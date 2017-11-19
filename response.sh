#!/bin/bash

settingsfile=$1
eval "$(cat $settingsfile)" # declare settings array

. misc.sh

declare -A server
server[remoteAddress]="$SOCAT_PEERADDR"
server[remotePort]="$SOCAT_PEERPORT"
server[localAddress]="$SOCAT_SOCKADDR"
server[localPort]="$SOCAT_SOCKPORT"

declare -A headers
first=1
while true; do
	IFS=$'\r' read header
	if test "$header" = ""; then
		break
	fi
	if test $first = 1; then
		server[method]="$(echo "$header" | awk '{ print $1 }')"
		server[http]="$(echo "$header" | awk '{ print $3 }' | awk -F/ '{ print $2} ')"
		server[user_path]=$(echo "$header" | awk '{ print $2 }')
		server[path]="$(realpath -sm "${server[user_path]}")"
		server[query]="$(echo "${server[path]}" | awk -F? '{for (i=2; i<=NF; i++) print $i}')"
		server[path]="$(echo "${server[path]}" | awk -F? '{ print $1 }')"
		server[real_path]="$(realpath -sm "${settings[home]}${server[path]}")"
		first=0
		continue
	fi
	headers[$(echo $header | awk -F: '{ print $1}')]="$(echo "$header" | awk '{for (i=2; i<=NF; i++) print $i}')"
done

if test "$first" = 1; then
	# wut?
	echo "$(date --rfc-3339=ns) - ${server[remoteAddress]}:${server[remotePort]} - Error: Malformed HTTP request; ignoring" 1>&2
	exit 1
fi

placeholder() {
	declare -A tokens
	tokens[path]="${server[path]}"
	tokens[host]="${headers[Host]}"
	tokens[server]="${settings[server]}"

	text="$(cat)"

	for key in "${!tokens[@]}"; do
		key="$(echo "$key" | sed -e 's/[]\/$*.^|[]/\\&/g')"
		value="$(echo "${tokens[$key]}" | sed -e 's/[]\/$*.^|[]/\\&/g')"

		text=$(echo "$text" | sed -e "s/\[$key\]/$value/g")

	done

	echo "$text"
}

addStatusContainer() {
	i=0
	container="/dev/shm/st-cont-$$-";
	while true; do
		if test -f "$container$i"; then
			i=$(($i+1))
			continue
		fi
		container="$container$i"
		break
	done
	touch "$container"
	echo "$container"
}
removeStatusContainer() {
	container="$1"
	rm "$container"
}

isExecutable() {
	path="$1"
	if test ! -x "$path" -o ! -f "$path"; then
		return 1
	fi
	ext="$(echo "$path" | awk -F. '{ print $NF }')"
	for i in ${settings[executeable]}; do
		if test "$ext" = "$i"; then
			return 0
		fi
	done
	return 1
}

baseSource="$(pwd)/base.source.sh"

status=500
content=""
declare -A responseHeaders
responseHeaders[Content-Type]="text/html"
responseHeaders[Server]="${settings[server]}"
responseHeaders[Connection]="max=1"

type=""

if test ! -e "${server[real_path]}"; then
	status=404

	content="$(placeholder < ./404.html)"

	type="-"
elif test "${settings[index]}" = "true" -a -d "${server[real_path]}"; then
	container="$(addStatusContainer)"
	content="$(./index.sh "$baseSource" "$container" "$(declare -p settings)" "$(declare -p server)" "$(declare -p headers)")"
	status=$(head -n 1 "$container")
	if test "$status" = ""; then
		status=200
	fi
	while read line; do
		responseHeaders[$(echo "$line" | awk -F: '{ print $1 }')]="$(echo "$line" | awk '{for (i=2; i<=NF; i++) print $i}')"
        done <<< $(tail -n 1 "$container")

	removeStatusContainer "$container"

	type="index"
elif $(isExecutable "${server[real_path]}"); then
	container="$(addStatusContainer)"
	pushd "$(dirname "${server[real_path]}")" > /dev/null
	content=$("${server[real_path]}" "$baseSource" "$container" "$(declare -p settings)" "$(declare -p server)" "$(declare -p headers)")
	popd > /dev/null
	status=$(head -n 1 "$container")
	if test "$status" = ""; then
		status=200
	fi
       	while read line; do
		if test "$(echo "$line" | grep ':')" = ""; then
			continue
		fi
		responseHeaders[$(echo "$line" | awk -F: '{ print $1 }')]="$(echo "$line" | awk '{for (i=2; i<=NF; i++) print $i}')"
	done <<< $(tail -n 1 "$container")
	
	removeStatusContainer "$container"

	type="exec"
else
	status=200
	#responseHeaders['Content-Type']="$(file -b --mime-type ${server[real_path]})"
	responseHeaders['Content-Type']="$(mimetype -b "${server[real_path]}")"
	content="$(cat ${server[real_path]})"

	type="static"
fi

length=$(printf "%s" "$content" | wc -c)

if test "${settings[verbose]}" -ge "0"; then
	echo "$(date --rfc-3339=ns) - ${server[remoteAddress]}:${server[remotePort]} - ${headers[Host]}${server[path]} - $type - $status - $length bytes" 1>&2
fi

echo -en "HTTP/1.1 $status $(./statusString.sh $status)\r\n"
echo -en "Content-Length: $length\r\n"
for key in ${!responseHeaders[@]}; do
	echo -en "$(urlencode "$key"): $(urlencode "${responseHeaders[$key]}")\r\n"
done
echo -en "\r\n"
printf "%s" "$content"

