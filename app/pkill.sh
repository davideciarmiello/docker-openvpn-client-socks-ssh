#!/bin/bash

PID=`ps -eaf | grep "$1" | grep -v grep | grep -v pkill.sh | awk '{print $1}'`
if [[ "" !=  "$PID" ]]; then
    echo "killing $1 con PID: $PID"
    kill -9 $PID
fi
