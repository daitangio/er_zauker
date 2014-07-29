#!/bin/bash
# Simple bash monitor to run on redis server
# every x seconds sample the redis and write out the number of processed file on a csv file (redirect stdout)
# Usage example
# ./perf_monitor.sh  >>/c/tmp/test.csv
# More complex example (you can see what is happening...)
# ./perf_monitor.sh  |tee -a /c/tmp/test2.csv
redis-cli set fscan:fileProcessed 0
x=15
echo "REDIS CONNECTIONS;FILES_PROCESSED;TIME"
while true; do
    echo $(redis-cli client list | wc -l)\;$(redis-cli get fscan:fileProcessed)\;\"$(date "+%d/%m/%y %H:%M:%S")\"
    sleep $x
done

