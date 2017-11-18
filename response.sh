#!/bin/bash

settingsfile=$1
eval "$(cat $settingsfile)" # declare settings array

declare -A headers
first=1
while true; do
	IFS=$'\r' read header
	if test "$header" = ""; then
		break
	fi
	if test $first = 1; then
		headers[method]=$(echo "$header" | awk '{ print $1 }')
		headers[http]=$(echo "$header" | awk '{ print $3 }' | awk -F/ '{ print $2} ')
		headers[path]=$(echo "$header" | awk '{ print $2 }')
		first=0
		continue
	fi
	headers[$(echo $header | awk -F: '{ print $1}')]="$(echo "$header" | awk '{for (i=2; i<=NF; i++) print $i}')"
done

rpath="$(realpath -sm "${headers[path]}")"
headers[query]="$(echo "$rpath" | awk -F? '{for (i=2; i<=NF; i++) print $i}')"
rpath="$(echo "$rpath" | awk -F? '{ print $1 }')"

path="${settings[home]}${rpath}"
path="$(realpath -sm "$path")"

urlencode() {
	python -c "import urllib, sys; print urllib.quote(sys.argv[1])"  "$1"
}

placeholder() {
	declare -A tokens
	tokens[path]="$rpath ($path)"
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
		if test -f $container$i; then
			i=$(($i+1))
			continue
		fi
		container=$container$i
		break
	done
	touch $container
	echo $container
}
removeStatusContainer() {
	container=$1
	rm $container
}

isExecutable() {
	path=$1
	if test ! -x $path -o ! -f $path; then
		return 1
	fi
	ext="$(echo $path | awk -F. '{ print $NF }')"
	for i in ${settings[executeable]}; do
		if test "$ext" = "$i"; then
			return 0
		fi
	done
	return 1
}

status=500
content=""
declare -A responseHeaders
responseHeaders[Content-Type]="text/html"
responseHeaders[Server]="${settings[server]}"


if test ! -e "$path"; then
	status=404

	content="$(placeholder < ./404.html)"

elif test ${settings[index]} = true -a -d "$path"; then
	container=$(addStatusContainer)
	content=$(./index.sh "${settings[server]}" "${headers[Host]}" "$rpath" "$path" "$container")
	status=$(cat $container)
	removeStatusContainer $container

elif $(isExecutable $path); then
	container=$(addStatusContainer)
	pushd "$(dirname $path)" > /dev/null
	content=$($path $container "$(declare -p settings)" "$(declare -p headers)")
	popd > /dev/null
	status=$(head -n 1 $container)
	if test "$status" = ""; then
		status=200
	fi
       	while read line; do
		responseHeaders[$(echo $line | awk -F: '{ print $1 }')]="$(echo "$line" | awk '{for (i=2; i<=NF; i++) print $i}')"
	done <<< $(tail -n 1 $container)
	
	removeStatusContainer $container
else
	status=200
	responseHeaders['Content-Type']="$(file -b --mime-type $path)"
	content=$(cat $path)
fi

length=$(printf "%s" "$content" | wc -c)

echo -en "HTTP/1.1 $status $(./statusString.sh $status)\r\n"
echo -en "Content-Length: $length\r\n"
for key in ${!responseHeaders[@]}; do
	echo -en "$(urlencode "$key"): $(urlencode "${responseHeaders[$key]}")\r\n"
done
echo -en "\r\n"
printf "%s" "$content"

