#!/bin/bash

echo "Start response.sh" 1>&2

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

content="<!DOCTYPE html>
<html>
	<head>
		<title>Test</title>
	</head>
	<body>
		<h1>Hallo Welt</h1>
		$(for key in ${!headers[@]}; do echo "$key" "->" "${headers[$key]}" "<br />"; done)
		<br />
		<br />
		$(for key in ${!settings[@]}; do echo "$key" "->" "${settings[$key]}" "<br />"; done)
	</body>
</html>
"

length=$(printf "%s" "$content" | wc -c)

echo "$length" 1>&2
echo "$content" 1>&2

echo -en "HTTP/1.1 200 OK\r\n"
echo -en "Content-Type: text/html\r\n"
echo -en "Server: testserver\r\n"
echo -en "Content-Length: $length\r\n"
echo -en "\r\n"
printf "%s" "$content"

