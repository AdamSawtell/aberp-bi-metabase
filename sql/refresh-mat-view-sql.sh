#!/bin/bash

#ACTION: update ID_HOST to point to iDempiere database
ID_HOST=localhost
REFRESH_FILE=/tmp/metabase_idempiere_bi_sql_refresh_sql.txt
REFRESH_RESULTS=/tmp/metabase_idempiere_bi_sql_refresh_results.txt

CONCURRENT_DEFAULT=""
PARAM=$1
CONCURRENT="${PARAM:-$CONCURRENT_DEFAULT}"
echo $CONCURRENT
#NOTE: only certain views can update concurrently. Example: must have unique index

REFRESH_SQL="
SELECT CONCAT('REFRESH MATERIALIZED VIEW $CONCURRENT adempiere.', relname,';') FROM pg_class JOIN adempiere.bi_mat_view_create_order o on pg_class.relname = o.name WHERE  relkind = 'm' AND relname LIKE 'bi_%' ORDER BY o.did"
echo Print for Reference:
echo $REFRESH_SQL

echo
echo Generating refresh DDL...
psql -h $ID_HOST -U adempiere -d idempiere -c "$REFRESH_SQL" &> $REFRESH_FILE
cat $REFRESH_FILE

echo
echo Refreshing materialized views
echo If any lines with 'psql' appear, view $REFRESH_FILE for errors.
cat $REFRESH_FILE | grep "REFRESH MAT" | psql -U adempiere -d idempiere -h $ID_HOST &> $REFRESH_RESULTS
cat $REFRESH_RESULTS | grep psql
cat $REFRESH_RESULTS
