#!/bin/bash

statusContainer=$1
eval "declare -A settings="${2#*=}
eval "declare -A headers="${3#*=}


if test "${headers[query]}" == ""; then
	echo 200 > $statusContainer

	cat<<EOF
<!DOCTYPE>
<html>
	<head>
		<title>Add to guestbook</title>
	</head>
	<body>
		<h1>Add something to the guestbook</h1>
		<form action="?" method="GET">
			<input name="name" type="text" placeholder="Your name"><br />
			<textarea name="text"></textarea><br />
			<input type="submit">
		</form>
	</body>
</html>
EOF
	exit 
fi

name=""
text=""

fields=$(echo ${headers[query]} | tr "&" "\n")
for field in $fields; do
	key=$(echo $field | awk -F= '{ print $1 }')
	value=$(echo $field | awk -F= '{for (i=2; i<=NF; i++) print $i}')

	if test "$key" = "name"; then
		name=$value
	elif test "$key" = "text"; then
		text=$value
	fi
done

if test "$name" = "" -o "$text" = ""; then
	echo 400 > $statusContainer
	echo 400 - Bad Request
	exit
fi

cat >> ./guestbook.txt <<EOF
===============================
$(date): $(python -c "import urllib, sys; print urllib.unquote_plus(sys.argv[1]).decode('utf8')" "$name")

$(python -c "import urllib, sys; print urllib.unquote_plus(sys.argv[1]).decode('utf8')"  "$text")

EOF

echo 302 > $statusContainer
echo "Location: ./guestbook.txt" >> $statusContainer
