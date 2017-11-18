#!/bin/bash

urlencode() {
	python -c "import urllib, sys; print urllib.quote(sys.argv[1])"  "$1"
}

urldecode() {
	python -c "import urllib, sys; print urllib.unquote_plus(sys.argv[1]).decode('utf8')"  "$1"
}
