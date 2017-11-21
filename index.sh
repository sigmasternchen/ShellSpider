#!/bin/bash

. $1

setStatusCode 200

cat <<EOF
<!DOCTYPE>
<html>
	<head>
		<title>Index of ${server[scriptName]}</title>
	</head>
	<body>
		<h1>Index of ${server[scriptName]}</h1>
		<hr />
		<table>
			<tr>
				<th>
					Name
				</th>
				<th>
					Type
				</th>
				<th>
					Executeable
				</th>
				<th>
					Size
				</th>
			</tr>
EOF

for file in $(ls -a "${server[scriptFilename]}"); do
	if test "$file" = ".." -a "${server[scriptName]}" = "/"; then
		continue;
	fi
	cat <<EOF
	<tr>
		<td>
			<a href="$(realpath -sm "${server[scriptName]}/$file")">$file</a>
		</td>
		<td>
			$(file -b "${server[scriptFilename]}/$file")
		</td>
		<td>
			$(if test ! -d "${server[scriptFilename]}/$file"; then if test -x "${server[scriptFilename]}/$file"; then echo yes; else echo no; fi; fi)
		</td>
		<td>
			$(if test ! -d "${server[scriptFilename]}/$file"; then du -kh "${server[scriptFilename]}/$file" | cut -f1; fi)
		</td>
	</tr>
EOF
done

cat <<EOF
			</table>
		<hr />
		${server[serverSignature]}
	</body>
</html>
EOF
