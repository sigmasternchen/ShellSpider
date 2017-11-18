#!/bin/bash

EXIT_FAILURE=1
EXIT_SUCCESS=0

port=-1
progname="server"

help() {
	cat << EOF
usage: $progname [OPTIONS] --port=PORT

Options:
  -p, --port=PORT      set port
  -h, --home=HOME      set home directory
  -v, --verbose	       set to verbose mode
  -q, --quiet          don't output anything
EOF
}

verboselevel=0
echoOnVerbose() {
	if test "$verboselevel" -ge $1; then
		echo -n "$2"
	fi
}

progname="$0"

OPTS=$(getopt -o "p:vqh:" -l "port:,verbose,quiet,home:" -- $@)
if test $? != 0; then
	exit $EXIT_FAILURE
fi

eval set -- "$OPTS"

home="./home/"

while true; do
	case "$1" in
		-p|--port) port=$2; shift 2;;
		-v|--verbose) verboselevel=$(($verboselevel+1)); shift;;
		-q|--quiet) verboselevel=-1; shift;;
		-h|--home) home=$2; shift 2;;
		--) shift; break;;
	esac
done

if test "$port" -lt 1; then
	help
	exit $EXIT_FAILURE
fi

settingsfile="/dev/shm/wserver-$$"
declare -A settings
settings[home]=$home
settings[verbose]=$verboselevel
settings[executeable]="sh php py cgi"
settings[server]="ShellSpider V1"
settings[index]="true"
declare -p settings > $settingsfile

echo "Starting... "
socat $(echoOnVerbose 2 "-vv") tcp-listen:$port,reuseaddr,fork SYSTEM:"./response.sh $settingsfile" > /dev/null

if test $? != 0; then
	exit $EXIT_FAILURE
fi
