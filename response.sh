#!/bin/bash

settingsfile=$1
eval "$(cat $settingsfile)" # declare settings array

. misc.sh

declare -A server
server[remoteAddress]="$SOCAT_PEERADDR"
server[remotePort]="$SOCAT_PEERPORT"
server[remoteHost]="$(dig +noall +answer -x $SOCAT_PEERADDR | awk '{ print $5 }')"
server[serverAddress]="$SOCAT_SOCKADDR"
server[serverPort]="$SOCAT_SOCKPORT"
server[serverName]="${settings[name]}"
server[serverAdmin]="${settings[admin]}"
server[serverSoftware]="${settings[server]}"
server[documentRoot]="$(realpath "${settings[home]}")"
server[requestTime]="$(date +%s)"
server[requestTimeFloat]="$(($(date +%s%N)/1000))"
server[requestTimeReadable]="$(date --rfc-3339=ns)"

declare -A headers
first=1
while true; do
	IFS=$'\r' read header
	if test "$header" = ""; then
		break
	fi
	if test $first = 1; then
		server[requestMethod]="$(echo "$header" | awk '{ print $1 }')"
		server[http]="$(echo "$header" | awk '{ print $3 }' | awk -F/ '{ print $2} ')"
		server[https]="off"
		server[serverProtocol]="$(echo "$header" | awk '{ print $3 }')"
		server[request_unchecked]=$(echo "$header" | awk '{ print $2 }')
		server[requestURI]="$(realpath -sm "${server[request_unchecked]}")"
		server[queryString]="$(echo "${server[requestURI]}" | awk -F? '{for (i=2; i<=NF; i++) print $i}')"
		server[scriptName]="$(echo "${server[requestURI]}" | awk -F? '{ print $1 }')"
		server[scriptFilename]="$(realpath -sm "${settings[home]}${server[scriptName]}")"
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

server[httpAccept]="${headers[Accept]}"
server[httpAcceptCharset]="${headers[Accept-Charset]}"
server[httpAcceptEncoding]="${headers[Accept-Encoding]}"
server[httpAcceptLanguage]="${headers[Accept-Language]}"
server[httpConnection]="${headers[Accept-Connection]}"
server[httpHost]="${headers[Host]}"
server[httpReferer]="${headers[Referer]}"
server[httpUserAgent]="${headers[User-Agent]}"

server[remoteUser]="" # TODO not implemented
server[redirectRemoteUser]="" # TODO not implemented
server[authType]="" # TODO not implemented

server[serverSignature]=""
if true; then # TODO add condition setting
	server[serverSignature]="${server[httpHost]} (${server[serverSoftware]})"
fi

placeholder() {
	declare -A tokens
	tokens[path]="${server[scriptName]}"
	tokens[host]="${server[httpHost]}"
	tokens[server]="${server[serverSoftware]}"
	tokens[signature]="${server[serverSignature]}"

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

isExecutableShell() {
	path="$1"
	if test ! -x "$path" -o ! -f "$path"; then
		return 1
	fi
	ext="$(echo "$path" | awk -F. '{ print $NF }')"
	for i in ${settings[shellExec]}; do
		if test "$ext" = "$i"; then
			return 0
		fi
	done
	return 1
}

isExecutableCGI() {
	path="$1"
	if test ! -x "$path" -o ! -f "$path"; then
		return 1
	fi
	ext="$(echo "$path" | awk -F. '{ print $NF }')"
	for i in ${settings[cgiExec]}; do
		if test "$ext" = "$i"; then
			return 0
		fi
	done
	return 1
}

isExecutablePHP() {
	path="$1"
	if test ! -x "$path" -o ! -f "$path"; then
		return 1
	fi
	ext="$(echo "$path" | awk -F. '{ print $NF }')"
	for i in ${settings[phpExec]}; do
		if test "$ext" = "$i"; then
			return 0
		fi
	done
	return 1
}

cgiExec() {
	export GATEWAY_INTERFACE="CGI/1.1"

	export AUTH_TYPE="${server[authType]}"
	export DOCUMENT_ROOT="${server[documentRoot]}"
	export HTTP_ACCEPT_CHARSET="${server[httpAcceptCharset]}"
	export HTTP_ACCEPT_ENCODING="${server[httpAcceptEncoding]}"
	export HTTP_ACCEPT_LANGUAGE="${server[httpAcceptLanguage]}"
	export HTTP_ACCEPT="${server[httpAccept]}"
	export HTTP_CONNECTION="${server[httpConnection]}"
	export HTTP_HOST="${server[httpHost]}"
	export HTTPS="${server[https]}"
	export HTTP_USER_AGENT="${server[httpUserAgent]}"
	export QUERY_STRING="${server[queryString]}"
	export REDIRECT_REMOTE_USER="${server[redirectRemoteUser]}"
	export REMOTE_ADDR="${server[remoteAddress]}"
	export REMOTE_HOST="${server[remoteHost]}"
	export REMOTE_PORT="${server[remotePort]}"
	export REMOTE_USER="${server[remoteUser]}"
	export REQUEST_METHOD="${server[requestMethod]}"
	export REQUEST_TIME_FLOAT="${server[requestTimeFloat]}"
	export REQUEST_TIME="${server[requestTime]}"
	export REQUEST_URI="${server[requestURI]}"
	export SCRIPT_FILENAME="${server[scriptFilename]}"
	export SCRIPT_NAME="${server[scriptName]}"
	export SERVER_ADDR="${server[serverAddress]}"
	export SERVER_ADMIN="${server[serverAdmin]}"
	export SERVER_NAME="${server[serverName]}"
	export SERVER_PORT="${server[serverPort]}"
	export SERVER_PROTOCOL="${server[serverProtocol]}"
	export SERVER_SIGNATURE="${server[serverSignature]}"
	export SERVER_SOFTWARE="${server[serverSoftware]}"

	"$1"
}
	

baseSource="$(pwd)/base.source.sh"

status=500
content=""
declare -A responseHeaders
responseHeaders[Content-Type]="text/html"
responseHeaders[Server]="${settings[server]}"
responseHeaders[Connection]="max=1"

type=""

if test ! -e "${server[scriptFilename]}"; then
	status=404

	content="$(placeholder < ./404.html)"

	type="-"
elif test "${settings[index]}" = "true" -a -d "${server[scriptFilename]}"; then
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
elif isExecutableShell "${server[scriptFilename]}"; then
	container="$(addStatusContainer)"
	pushd "$(dirname "${server[scriptFilename]}")" > /dev/null
	content=$("${server[scriptFilename]}" "$baseSource" "$container" "$(declare -p settings)" "$(declare -p server)" "$(declare -p headers)")
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

	type="shell"
elif isExecutableCGI "${server[scriptFilename]}"; then
	content=""
	status=200
	headerDone=0
	while read line; do
		if test $headerDone = 1; then
			content="${content}${line}"$'\n'
			continue
		fi
		if test "$(echo "$line" | grep ':')" = ""; then
			headerDone=1
			continue
		fi
		if test "$(echo "$line" | awk -F: '{print $1}')" = "Status"; then
			status="$(echo "$line" | awk '{print $2}')"
			continue
		fi
		responseHeaders[$(echo "$line" | awk -F: '{ print $1 }')]="$(echo "$line" | awk '{for (i=2; i<=NF; i++) print $i}')"
	done <<< $( # open subshell
		cgiExec "${server[scriptFilename]}"
	)

	type="cgi"
elif isExecutablePHP "${server[scriptFilename]}"; then
	content=""
	status=200
	headerDone=0
	while read line; do
		if test $headerDone = 1; then
			content="${content}${line}"$'\n'
			continue
		fi
		if test "$(echo "$line" | grep ':')" = ""; then
			headerDone=1
			continue
		fi
		if test "$(echo "$line" | awk -F: '{print $1}')" = "Status"; then
			status="$(echo "$line" | awk '{print $2}')"
			continue
		fi
		responseHeaders[$(echo "$line" | awk -F: '{ print $1 }')]="$(echo "$line" | awk '{for (i=2; i<=NF; i++) print $i}')"
	done <<< $( # open subshell
		export REDIRECT_STATUS=1
		cgiExec php-cgi -f "${server[scriptFilename]}"
	)

	type="php"

else
	status=200
	#responseHeaders['Content-Type']="$(file -b --mime-type ${server[scriptFilename]})"
	responseHeaders['Content-Type']="$(mimetype -b "${server[scriptFilename]}")"
	content="$(cat ${server[scriptFilename]})"

	type="static"
fi

length=$(printf "%s" "$content" | wc -c)

if test "${settings[verbose]}" -ge "0"; then
	echo "$(date --rfc-3339=ns) - ${server[remoteAddress]}:${server[remotePort]} - ${headers[Host]}${server[queryURI]} - $type - $status - $length bytes" 1>&2
fi

echo -en "HTTP/1.1 $status $(./statusString.sh $status)\r\n"
echo -en "Content-Length: $length\r\n"
for key in ${!responseHeaders[@]}; do
	#echo -en "$(urlencode "$key"): $(urlencode "${responseHeaders[$key]}")\r\n"
	echo -en "$key: ${responseHeaders[$key]}\r\n"
done
echo -en "\r\n"
printf "%s" "$content"

