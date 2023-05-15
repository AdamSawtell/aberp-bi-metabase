-- copy this file to a file named delme_xxx and make the below changes there
-- replace CHANGEME with desired bi table name - example: warehouse
-- replace xxx with actual table name - example: m_warehouse
-- relace chgme with logical prefix - example: wh
-- example replace statement: ":%s/CHANGEME/warehouse/g"

CREATE VIEW bi_CHANGEME AS
--{{{
SELECT
c.*,
chgme.xxx_id as CHANGEME_id,
chgme.value as CHANGEME_search_key,
chgme.name as CHANGEME_name,
chgme.value||'_'||chgme.name as CHANGEME_search_key_name,
chgme.isisummary as CHANGEME_summary,
chgme.description as CHANGEME_description
FROM xxx chgme
JOIN bi_client_cache c on chgme.ad_client_id = c.client_id
;
SELECT 'chgme.'||column_name||',' as CHANGEME FROM information_schema.columns WHERE  table_name = 'bi_CHANGEME';
--SELECT COUNT(*) as CHANGEME_count FROM bi_CHANGEME;
CREATE MATERIALIZED VIEW bi_CHANGEME_cache as select * from bi_CHANGEME;
create unique index bi_CHANGEME_cache_idx on bi_CHANGEME_cache (CHANGEME_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_CHANGEME_cache');
--add all materialized view indexes here...

--join clause to add to additional tables if needed
--be sure to change YYY manually based on where you are adding the table
--left join bi_CHANGEME_cache chgme on YYY.xxx_id = chgme.CHANGEME_id
--}}}
