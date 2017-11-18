#!/bin/bash

statusContainer=$1
eval "declare -A settings="${2#*=}
eval "declare -A headers="${3#*=}

echo 200 > $statusContainer

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
		<h1>Headers</h1>
EOF
for key in "${!headers[@]}"; do
	echo "$key -> ${headers[$key]}<br />"
done
cat << EOF
	</body>
</html>

EOF
