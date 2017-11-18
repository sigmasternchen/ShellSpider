#!/bin/bash

. $1

setStatusCode 200

cat <<EOF
<!DOCTYPE html>
<html>
	<head>
		<title>Info</title>
	</head>
	<body>
		<h1>Settings</h1>
EOF
for key in "${!settings[@]}"; do
	echo "$key -> ${settings[$key]}<br />"
done
cat <<EOF
		<h1>Server</h1>
EOF
for key in "${!server[@]}"; do
	echo "$key -> ${server[$key]}<br />"
done
cat <<EOF
		<h1>Headers</h1>
EOF
for key in "${!headers[@]}"; do
	echo "$key -> ${headers[$key]}<br />"
done
cat <<EOF
	</body>
</html>

EOF
