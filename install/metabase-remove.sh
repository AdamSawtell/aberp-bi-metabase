#!/bin/bash

SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P  )
cd $SCRIPT_PATH

source ./metabase.properties

/opt/$MB_OS_USER/metabase-stop.sh
echo wait for metabase to stop...
sleep 4
sudo rm -r /opt/$MB_OS_USER
sudo userdel $MB_OS_USER
sudo rm -r /home/$MB_OS_USER
sudo -u postgres psql -c "drop database $MB_DB_DBNAME"
sudo -u postgres psql -c "drop role $MB_DB_DBNAME"
