#!/bin/bash

. $1

setStatusCode 200

cat <<EOF
<!DOCTYPE>
<html>
	<head>
		<title>Index of ${server[path]}</title>
	</head>
	<body>
		<h1>Index of ${server[path]}</h1>
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

for file in $(ls -a ${server[real_path]}); do
	if test "$file" = ".." -a "${server[path]}" = "/"; then
		continue;
	fi
	cat <<EOF
	<tr>
		<td>
			<a href="$(realpath -sm "${server[path]}/$file")">$file</a>
		</td>
		<td>
			$(file -b ${server[real_path]}/$file)
		</td>
		<td>
			$(if test ! -d ${server[real_path]}/$file; then if test -x ${server[real_path]}/$file; then echo yes; else echo no; fi; fi)
		</td>
		<td>
			$(if test ! -d ${server[real_path]}/$file; then du -kh ${server[real_path]}/$file | cut -f1; fi)
		</td>
	</tr>
EOF
done

cat <<EOF
			</table>
		<hr />
		${headers[Host]} (${settings[server]})
	</body>
</html>
EOF
