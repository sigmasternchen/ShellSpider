#!/bin/bash

statusContainer=$1
eval "declare -A settings="${2#*=}
eval "declare -A headers="${3#*=}

echo 302 > $statusContainer
echo "Location: ../stuff/guestbook.txt" >> $statusContainer
