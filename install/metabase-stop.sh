#!/bin/bash

SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P  )
cd $SCRIPT_PATH

source ./metabase.properties

# stop all processes by this user
sudo pkill -u $MB_OS_USER
