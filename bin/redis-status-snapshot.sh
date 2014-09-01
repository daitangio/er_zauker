#!/bin/bash
#uptime
#echo Connections:   $(redis-cli client list | wc -l ) 
# Magic <() to avoid useless temp files
egrep "clients|human|mem_|db0" <(redis-cli  <<EOF
info Clients
info Keyspace
info Memory
EOF
)
#free
