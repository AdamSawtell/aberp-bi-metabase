
-- command to execute this file:
-- sudo -u postgres psql -d metabase -f utils.sql

update metabase_table 
set visibility_type = 'hidden'
where db_id in (select id from metabase_database where is_sample = 'no')
;

update metabase_table 
set visibility_type = null
where name like 'bi%cache%'
and db_id in (select id from metabase_database where is_sample = 'no')
;

update metabase_table
set display_name = replace(display_name,' Cache', '')
where name like '%cache'
;

update metabase_table
set display_name = replace(display_name,'Bi ', '')
where name like 'bi%'
;

update metabase_table
set display_name = 'Unit of Measure'
where name like 'bi_uom%'
;

update metabase_table
set display_name = 'Business Partner'
where name like 'bi_bpartner%'
;

update metabase_table
set display_name = 'Ship/Receipt'
where name like 'bi_inout%'
;

update metabase_table
set display_name = 'Ship/Receipt Line'
where name like 'bi_inout_line%'
;
