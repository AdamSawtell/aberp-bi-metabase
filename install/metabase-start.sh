#!/bin/bash

SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P  )
cd $SCRIPT_PATH

source ./metabase.properties

#echo MB_DB_TYPE = $MB_DB_TYPE
#echo MB_DB_DBNAME = $MB_DB_DBNAME
#echo MB_DB_PORT = $MB_DB_PORT
#echo MB_DB_USER = $MB_DB_USER
#echo MB_DB_PASS = $MB_DB_PASS
#echo MB_DB_HOST = $MB_DB_HOST

sudo -u $MB_OS_USER \
    MB_DB_TYPE=$MB_DB_TYPE \
    MB_DB_DBNAME=$MB_DB_DBNAME \
    MB_DB_PORT=$MB_DB_PORT \
    MB_DB_USER=$MB_DB_USER \
    MB_DB_PASS=$MB_DB_PASS \
    MB_DB_HOST=$MB_DB_HOST \
    nohup java -jar metabase.jar > metabase.log 2>&1 &
echo $! > save_pid.txt
