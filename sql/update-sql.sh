#!/bin/bash
ID_HOST=localhost
VIEW_FILE=/tmp/metabase_idempiere_bi_sql_view_out.txt
ACCESS_FILE=/tmp/metabase_idempiere_bi_sql_access_out.txt

echo
echo Installing views...
psql -h $ID_HOST -U adempiere -d idempiere -f aberp_bi_init_views.sql &> $VIEW_FILE

echo
echo Checking for errors...
echo If any lines with 'psql' appear, view $VIEW_FILE for errors.
cat $VIEW_FILE | grep psql

echo
echo Updating BI view access rights...
echo If any lines with 'psql' appear, view $ACCESS_FILE for errors.
cat $VIEW_FILE | grep "GRANT SELECT" | psql -U adempiere -d idempiere -h $ID_HOST &> $ACCESS_FILE
cat $ACCESS_FILE | grep psql

echo
echo Refreshing materialized views
./refresh-mat-view-sql.sh
