# ShellSpider
A web-server in shell script

Why?
====
Because I can.

Requirements
============
- an up-to-date version of bash
- socat (for networking)
- python (for url-encoding)
- dig (for reverse lookup)
- some other basic tools, like sed, grep, awk, getopt

Usage
=====

```
./server.sh --port=[PORT]
```

For other options start the script without the port-option.

Why again?
==========
I did this just for fun. I wanted to reach the limits of shell scripts. Turned out: Building a fully functional webserver is possible.
