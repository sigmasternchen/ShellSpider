#!/bin/bash

statusContainer="$2"
eval "$3" # settings
eval "$4" # server
eval "$5" # headers

. ${settings[serverDirectory]}/misc.sh

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
