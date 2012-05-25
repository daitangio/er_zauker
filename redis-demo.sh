#!/bin/bash
echo Redis Client test
c=redis-cli 
setkey="log:set"
if [ "$*" != "" ]; then
    echo Logging $*    
    set -x -e
    i=$($c incr log:uid)    
    key="log:$(date +%Y%m%d_%H_%M_%S):$i:demo-module:DEBUG"
    # I register on log set
    $c sadd $setkey $key
    # II: register the log...with an expiration
    $c set $key  "$*"
    $c expire $key 3600
    $c smembers $setkey
else
    echo "LOG CONSUMER"
    while true; do
	for one in $($c smembers $setkey | sort); do
	    echo LOG $one $($c get $one)
	    $c DEL $one          >/dev/null
	    $c SREM $setkey $one >/dev/null
	done
	sleep 1
    done
fi
