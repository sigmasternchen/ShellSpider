#!/bin/bash

server="$1"
host="$2"
rpath="$3"
path="$4"
statuscontainer=$5

echo 200 > $statuscontainer

cat <<EOF
<!DOCTYPE>
<html>
	<head>
		<title>Index of $rpath</title>
	</head>
	<body>
		<h1>Index of $rpath</h1>
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

for file in $(ls -a $path); do
	if test "$file" = ".." -a "$rpath" = "/"; then
		continue;
	fi
	cat <<EOF
	<tr>
		<td>
			<a href="$(realpath -sm "$rpath/$file")">$file</a>
		</td>
		<td>
			$(file -b $path/$file)
		</td>
		<td>
			$(if test ! -d $path/$file; then if test -x $path/$file; then echo yes; else echo no; fi; fi)
		</td>
		<td>
			$(if test ! -d $path/$file; then du -kh $path/$file | cut -f1; fi)
		</td>
	</tr>
EOF
done

cat <<EOF
			</table>
		<hr />
		$host ($server)
	</body>
</html>
EOF
