#!/bin/bash

statusContainer="$2"
eval "$3" # settings
eval "$4" # server
eval "$5" # headers

. ${settings[serverDirectory]}/misc.sh

declare -A query
fields="$(echo "${server[query]}" | tr '&' '\n')"
for field in $fields; do
	key="$(echo "$field" | awk -F= '{ print $1 }')"
	value="$(echo "$field" | awk -F= '{ for (i=2; i<=NF; i++) print $i }')"
	query["$(urldecode "$key")"]="$(urldecode "$value")"
done

echo 200 > $statusContainer

setStatusCode() {
	status=$1
	sed -i "1s/.*/$status/" $statusContainer
}

addResponseHeader() {
	key=$1
	value=$2
	echo "$key: $value" >> $statusContainer
}

redirect() {
	setStatusCode 302
	addResponseHeader Location "$1"
}
