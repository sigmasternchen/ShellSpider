#!/bin/bash

. $1

if test "${server[query]}" == ""; then
	setStatusCode 200

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

fields=$(echo ${server[query]} | tr "&" "\n")
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
	setStatusCode 400
	exit
fi

cat >> ./guestbook.txt <<EOF
===============================
$(date): $(urldecode "$name")

$(urldecode "$text")

EOF

redirect "./guestbook.txt"
