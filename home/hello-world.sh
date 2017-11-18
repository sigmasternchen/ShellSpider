#!/bin/bash

statusContainer=$1
eval "declare -A settings="${2#*=}
eval "declare -A headers="${3#*=}

echo 200 > $statusContainer

cat <<EOF
<!DOCTYPE html>
<html>
	<head>
		<title>Hello World</title>
	</head>
	<body>
		<h1>Hello World</h1>
	</body>
</html>

EOF
