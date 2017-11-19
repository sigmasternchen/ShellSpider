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

name="${query["name"]}"
text="${query["text"]}"

if test "$name" = "" -o "$text" = ""; then
	setStatusCode 400
	exit
fi

cat >> ./guestbook.txt <<EOF
===============================
$(date): $name

$text

EOF

redirect "./guestbook.txt"
