#!/bin/bash

SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P  )
cd $SCRIPT_PATH

source ./metabase.properties

sudo -u postgres pg_dump --clean --create -d $MB_DB_DBNAME > metabase.dmp

# to reinstall the database from a previous backup
# 1. stop metabase
# 2. issue: sudo -u postgres psql -f metabase.dmp
