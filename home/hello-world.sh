#!/bin/bash

. $1

setStatusCode 200

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
