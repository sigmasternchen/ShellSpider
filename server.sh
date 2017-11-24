#!/bin/bash

EXIT_FAILURE=1
EXIT_SUCCESS=0

progname="server"

home="./home/"
name="localhost"
admin="admin@localhost"

httpPort=-1
httpsPort=-1
cert="./server.pem"

help() {
	cat << EOF
usage: $progname [OPTIONS]

Options:
  -p, --http-port=PORT    set unencrypted port
  -s, --https-port=PORT   set encrypted port
  -c, --cert=CERT         set SSL certificate (pem format) (default: ./server.pem) 
  -h, --home=HOME         set home directory (default: ./home/)
  -n, --name=NAME         set the name of the server (e.g. example.com) (default: localhost)
      --admin=ADMIN       set the admin mail address (default: admin@localhost)
  -v, --verbose	          set to verbose mode
  -q, --quiet             don't output anything (not implemented)

Ether an encrypted or an unencrypted port (or both) has to be given.
EOF
}

verboselevel=0
echoOnVerbose() {
	if test "$verboselevel" -ge $1; then
		echo -n "$2"
	fi
}

progname="$0"

OPTS=$(getopt -o "p:vqh:n:s:c:" -l "http-port:,verbose,quiet,home:,name:,admin:,https-port:,cert:" -- $@)
if test $? != 0; then
	exit $EXIT_FAILURE
fi

eval set -- "$OPTS"

while true; do
	case "$1" in
		-p|--http-port) httpPort=$2; shift 2;;
		-s|--https-port) httpsPort=$2; shift 2;;
		-c|--cert) cert=$2; shift 2;;
		-v|--verbose) verboselevel=$(($verboselevel+1)); shift;;
		-q|--quiet) verboselevel=-1; shift;;
		-h|--home) home=$2; shift 2;;
		-n|--name) name=$2; shift 2;;
		--admin) admin=$2; shift 2;;
		--) shift; break;;
	esac
done

if test "$httpPort" -lt 1 -a "$httpsPort" -lt 1; then
	help
	exit $EXIT_FAILURE
fi

settingsfile="/dev/shm/wserver-$$.settings"

logfile="/dev/shm/wserver-$$.log"

echo -n > "$logfile"

declare -A settings
settings[serverDirectory]="$(pwd)"
settings[logFile]="$logfile"
settings[home]="$home"
settings[name]="$name"
settings[admin]="$admin"
settings[verbose]=$verboselevel
settings[shellExec]="sh"
settings[cgiExec]="cgi"
settings[phpExec]="php"
settings[server]="ShellSpider V1"
settings[index]="true"
declare -p settings > $settingsfile

if test ! "$httpPort" -lt 1; then 
	echo "Starting unencrypted on port $httpPort ..."
	socat $(echoOnVerbose 2 "-vv") tcp-listen:$httpPort,reuseaddr,fork SYSTEM:"./response.sh $settingsfile off" > /dev/null &
fi
if test ! "$httpsPort" -lt 1; then
	echo "Starting encrypted on port $httpsPort ..."
	socat $(echoOnVerbose 2 "-vv") openssl-listen:$httpsPort,verify=0,cert="$cert",reuseaddr,fork SYSTEM:"./response.sh $settingsfile on" > /dev/null &
fi

while true; do 
	tail -f $logfile
done
