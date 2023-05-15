#!/bin/bash

-- The purpose of this script is to help you create views that are easily used inside a BI or analytics tool.
--{{{

--Missing Tables
-- timeexpense/line
--}}}

------ create biaccess credentials -------
--{{{
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT                       -- SELECT list can stay empty for this
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'biaccess') THEN

      CREATE ROLE biaccess;
   END IF;
END
$do$;

GRANT USAGE ON SCHEMA adempiere TO biaccess;
ALTER USER biaccess WITH PASSWORD 'flamingo'; --CHANGEME!!!
ALTER USER biaccess  WITH LOGIN;
--NOTE: access to specific credentials listed below.
--NOTE: metabase is very aggressive. If you do not restrict access to only views, it will lock down tables. 
--}}}

------ convenience functions -------
--{{{
--
-- Name: doctypemultiplier_bicm(numeric); Type: FUNCTION; Schema: adempiere; Owner: adempiere
--
CREATE OR REPLACE FUNCTION adempiere.doctypemultiplier_bicm(numeric) RETURNS numeric
    LANGUAGE sql
    AS $_$
-- used to determine a Document Type is a credit memo
Select CASE
            WHEN charat(docbasetype::character varying, 3)::text = 'C'::text THEN (-1.0)
            ELSE 1.0 END
from c_doctype
where c_doctype_id = $1
$_$ SECURITY DEFINER;
ALTER FUNCTION adempiere.doctypemultiplier_bicm(numeric) OWNER TO adempiere;

--
-- Name: doctypemultiplier_birp(numeric); Type: FUNCTION; Schema: adempiere; Owner: adempiere
--
CREATE OR REPLACE FUNCTION adempiere.doctypemultiplier_birp(numeric) RETURNS numeric
    LANGUAGE sql
    AS $_$
-- used to determine a Document Type is a AP (-) or AR (+)
Select CASE
            WHEN charat(docbasetype::character varying, 2)::text = 'P'::text THEN (-1.0) -- invoices
            WHEN charat(docbasetype::character varying, 1)::text = 'P'::text THEN (-1.0) -- orders
            ELSE 1.0 END 
from c_doctype
where c_doctype_id = $1
$_$ SECURITY DEFINER;
ALTER FUNCTION adempiere.doctypemultiplier_birp(numeric) OWNER TO adempiere;
--}}}

--Drop Views and other artifacts
--{{{
DROP TABLE IF EXISTS bi_mat_view_create_order;
--add new tables here
DROP MATERIALIZED VIEW IF EXISTS bi_project_line_cache;
DROP VIEW IF EXISTS bi_project_line;
DROP MATERIALIZED VIEW IF EXISTS bi_project_issue_cache;
DROP VIEW IF EXISTS bi_project_issue;
DROP MATERIALIZED VIEW IF EXISTS bi_production_line_cache;
DROP VIEW IF EXISTS bi_production_line;
DROP MATERIALIZED VIEW IF EXISTS bi_production_cache;
DROP VIEW IF EXISTS bi_production;
DROP MATERIALIZED VIEW IF EXISTS bi_request_cache;
DROP VIEW IF EXISTS bi_request;
DROP MATERIALIZED VIEW IF EXISTS bi_requisition_line_cache;
DROP VIEW IF EXISTS bi_requisition_line;
DROP MATERIALIZED VIEW IF EXISTS bi_requisition_cache;
DROP VIEW IF EXISTS bi_requisition;
DROP MATERIALIZED VIEW IF EXISTS bi_payment_cache;
DROP VIEW IF EXISTS bi_payment;
DROP MATERIALIZED VIEW IF EXISTS bi_bank_account_cache;
DROP VIEW IF EXISTS bi_bank_account;
DROP MATERIALIZED VIEW IF EXISTS bi_bank_cache;
DROP VIEW IF EXISTS bi_bank;
DROP MATERIALIZED VIEW IF EXISTS bi_inout_line_cache;
DROP VIEW IF EXISTS bi_inout_line;
DROP MATERIALIZED VIEW IF EXISTS bi_inout_cache;
DROP VIEW IF EXISTS bi_inout;
DROP MATERIALIZED VIEW IF EXISTS bi_invoice_line_cache;
DROP VIEW IF EXISTS bi_invoice_line;
DROP MATERIALIZED VIEW IF EXISTS bi_invoice_cache;
DROP VIEW IF EXISTS bi_invoice;
DROP MATERIALIZED VIEW IF EXISTS bi_order_line_cache;
DROP VIEW IF EXISTS bi_order_line;
DROP MATERIALIZED VIEW IF EXISTS bi_project_phase_cache;
DROP VIEW IF EXISTS bi_project_phase;
DROP MATERIALIZED VIEW IF EXISTS bi_order_cache;
DROP VIEW IF EXISTS bi_order;
DROP MATERIALIZED VIEW IF EXISTS bi_project_cache;
DROP VIEW IF EXISTS bi_project;
DROP MATERIALIZED VIEW IF EXISTS bi_campaign_cache;
DROP VIEW IF EXISTS bi_campaign;
DROP MATERIALIZED VIEW IF EXISTS bi_channel_cache;
DROP VIEW IF EXISTS bi_channel;
DROP MATERIALIZED VIEW IF EXISTS bi_department_cache;
DROP VIEW IF EXISTS bi_department;
DROP MATERIALIZED VIEW IF EXISTS bi_activity_cache;
DROP VIEW IF EXISTS bi_activity;
DROP MATERIALIZED VIEW IF EXISTS bi_product_cache;
DROP VIEW IF EXISTS bi_product;
DROP MATERIALIZED VIEW IF EXISTS bi_charge_cache;
DROP VIEW IF EXISTS bi_charge;
DROP MATERIALIZED VIEW IF EXISTS bi_locator_cache;
DROP VIEW IF EXISTS bi_locator;
DROP MATERIALIZED VIEW IF EXISTS bi_warehouse_cache;
DROP VIEW IF EXISTS bi_warehouse;
DROP MATERIALIZED VIEW IF EXISTS bi_user_cache;
DROP VIEW IF EXISTS bi_user;
DROP MATERIALIZED VIEW IF EXISTS bi_partner_location_cache;
DROP VIEW IF EXISTS bi_partner_location;
DROP MATERIALIZED VIEW IF EXISTS bi_location_cache;
DROP VIEW IF EXISTS bi_location;
DROP MATERIALIZED VIEW IF EXISTS bi_bpartner_cache;
DROP VIEW IF EXISTS bi_bpartner;
DROP MATERIALIZED VIEW IF EXISTS bi_price_list_version_cache;
DROP VIEW IF EXISTS bi_price_list_version;
DROP MATERIALIZED VIEW IF EXISTS bi_price_list_cache;
DROP VIEW IF EXISTS bi_price_list;
DROP MATERIALIZED VIEW IF EXISTS bi_currency_cache;
DROP VIEW IF EXISTS bi_currency;
DROP MATERIALIZED VIEW IF EXISTS bi_currency_type_cache;
DROP VIEW IF EXISTS bi_currency_type;
DROP MATERIALIZED VIEW IF EXISTS bi_uom_cache;
DROP VIEW IF EXISTS bi_uom;
DROP MATERIALIZED VIEW IF EXISTS bi_tax_cache;
DROP VIEW IF EXISTS bi_tax;
DROP MATERIALIZED VIEW IF EXISTS bi_tax_category_cache;
DROP VIEW IF EXISTS bi_tax_category;
DROP MATERIALIZED VIEW IF EXISTS bi_org_cache;
DROP VIEW IF EXISTS bi_org;
DROP MATERIALIZED VIEW IF EXISTS bi_client_cache;
DROP VIEW IF EXISTS bi_client;
--}}}

--create table to allow refresh materialized views in the order they were created
--{{{
CREATE TABLE adempiere.bi_mat_view_create_order (
     did    integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
     name   varchar(100) NOT NULL CHECK (name <> '')
);
--}}}

CREATE VIEW bi_client AS
--{{{
SELECT c.name AS client_name,
c.ad_client_id as client_id
FROM ad_client c;
SELECT 'c.'||column_name||',' as client FROM information_schema.columns WHERE  table_name   = 'bi_client';
--SELECT COUNT(*) as client_count FROM bi_client;
CREATE MATERIALIZED VIEW bi_client_cache AS select * from bi_client;
create unique index bi_client_cache_uidx on bi_client_cache (client_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_client_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_org AS
--{{{
SELECT 
o.name AS org_name,
o.value AS org_search_key, o.ad_org_id as org_id,
o.isactive AS org_active
FROM ad_org o
WHERE o.issummary = 'N'::bpchar;
SELECT 'o.'||column_name||',' as org FROM information_schema.columns WHERE  table_name   = 'bi_org';
--SELECT COUNT(*) as org_count FROM bi_org;
CREATE MATERIALIZED VIEW bi_org_cache AS select * from bi_org;
create unique index bi_org_cache_uidx on bi_org_cache (org_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_org_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_tax_category as
--{{{
SELECT
c.*,
-- assuming no org needed
tc.c_taxcategory_id as tax_category_id,
tc.name as tax_category_name,
tc.description as tax_category_description,
tc.created as tax_category_created,
tc.updated as tax_category_updated
from c_taxcategory tc
join bi_client_cache c on tc.ad_client_id = c.client_id;
SELECT 'tc.'||column_name||',' as tax_category FROM information_schema.columns WHERE  table_name   = 'bi_tax_category';
--SELECT COUNT(*) as tax_cat_count FROM bi_tax_category;
CREATE MATERIALIZED VIEW bi_tax_category_cache as select * from bi_tax_category;
create unique index bi_tax_category_cache_uidx on bi_tax_category_cache (tax_category_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_tax_category_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_tax as
--{{{
SELECT
c.*,
t.c_tax_id as tax_id,
t.name as tax_name,
t.description as tax_description,
t.isactive as tax_active,
t.rate as tax_rate,
t.taxindicator as tax_indicator,
t.created as tax_created,
t.updated as tax_updated,
tc.tax_category_name,
tc.tax_category_description
FROM c_tax t
JOIN bi_client_cache c on t.ad_client_id = c.client_id
JOIN bi_tax_category_cache tc on t.c_taxcategory_id = tc.tax_category_id
;
SELECT 't.'||column_name||',' as tax FROM information_schema.columns WHERE  table_name   = 'bi_tax';
--SELECT COUNT(*) as tax_count FROM bi_tax;
CREATE MATERIALIZED VIEW bi_tax_cache as select * from bi_tax;
create unique index bi_tax_cache_uidx on bi_tax_cache (tax_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_tax_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_uom AS
--{{{
SELECT uom.c_uom_id as uom_id,
c.*,
-- assuming no org needed
uom.name AS uom_name, 
uom.uomsymbol AS uom_search_key, 
uom.created as uom_created,
uom.updated as uom_updated,
uom.isactive AS uom_active
FROM c_uom uom
JOIN bi_client_cache c on uom.ad_client_id=c.client_id;
SELECT 'uom.'||column_name||',' as uom FROM information_schema.columns WHERE  table_name   = 'bi_uom';
--SELECT COUNT(*) as uom_count FROM bi_uom;
CREATE MATERIALIZED VIEW bi_uom_cache AS select * from bi_uom;
create unique index bi_uom_cache_uidx on bi_uom_cache (uom_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_uom_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_currency_type AS
--{{{
SELECT
c.*,
currtype.c_conversiontype_id as currency_type_id,
currtype.value as currency_type_search_key,
currtype.name as currency_type_name,
currtype.description as currency_type_description,
currtype.created as currency_type_created,
currtype.updated as currency_type_updated
FROM c_conversiontype currtype
join bi_client_cache c on currtype.ad_client_id = c.client_id
;
SELECT 'currtype.'||column_name||',' as currency_type FROM information_schema.columns WHERE  table_name   = 'bi_currency_type';
--SELECT COUNT(*) as currency_type_count FROM bi_currency_type;
CREATE MATERIALIZED VIEW bi_currency_type_cache AS select * from bi_currency_type;
create unique index bi_currency_type_cache_uidx on bi_currency_type_cache (currency_type_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_currency_type_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_currency AS
--{{{
SELECT
c.*,
curr.c_currency_id as currency_id,
curr.iso_code as currency_iso_code,
curr.cursymbol as currency_symbol,
curr.description as currency_description,
curr.isactive as currency_active,
curr.stdprecision as currency_standard_precision,
curr.costingprecision as currency_costing_precision
FROM c_currency curr
join bi_client_cache c on curr.ad_client_id = c.client_id
;
SELECT 'curr.'||column_name||',' as currency FROM information_schema.columns WHERE  table_name   = 'bi_currency';
--SELECT COUNT(*) as currency_count FROM bi_currency;
CREATE MATERIALIZED VIEW bi_currency_cache AS select * from bi_currency;
create unique index bi_currency_cache_uidx on bi_currency_cache (currency_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_currency_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_price_list AS
--{{{
SELECT
c.*,
pl.m_pricelist_id as price_list_id,
pl.name as price_list_name,
pl.description as price_list_description,
pl.isactive as price_list_active,
pl.isdefault as price_list_default,
pl.priceprecision as price_list_precision,
pl.issopricelist as price_list_sales,
pl.istaxincluded as price_list_tax_included,
pl.enforcepricelimit as price_list_enforce_limit,
pl.created as price_list_created,
pl.updated as price_list_updated,

curr.currency_iso_code as price_list_currency_iso_code,
curr.currency_symbol as price_list_currency_symbol,
curr.currency_description as price_list_currency_description

FROM m_pricelist pl
JOIN bi_client_cache c on pl.ad_client_id = c.client_id
JOIN bi_currency_cache curr on pl.c_currency_id = curr.currency_id
;
SELECT 'pl.'||column_name||',' as Price_List FROM information_schema.columns WHERE  table_name   = 'bi_price_list';
--SELECT COUNT(*) as price_list_count FROM bi_price_list;
CREATE MATERIALIZED VIEW bi_price_list_cache AS select * from bi_price_list;
create unique index bi_price_list_cache_uidx on bi_price_list_cache (price_list_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_price_list_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_price_list_version AS
--{{{
SELECT
pl.*,
plv.m_pricelist_version_id as price_list_version_id,
plv.name as price_list_version_name,
plv.description as price_list_version_description,
plv.created as price_list_version_created,
plv.updated as price_list_version_updated,
plv.isactive as price_list_version_active
FROM m_pricelist_version plv
JOIN bi_price_list_cache pl on plv.m_pricelist_id = pl.price_list_id
;
SELECT 'plv.'||column_name||',' as Price_List_Version FROM information_schema.columns WHERE  table_name   = 'bi_price_list_version';
--SELECT COUNT(*) as price_list_version_count FROM bi_price_list_version;
CREATE MATERIALIZED VIEW bi_price_list_version_cache AS select * from bi_price_list_version;
create unique index bi_price_list_version_cache_uidx on bi_price_list_version_cache (price_list_version_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_price_list_version_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_bpartner AS
--{{{
SELECT
c.*,
-- assuming no org needed
bp.c_bpartner_id as bpartner_id,
bp.value AS bpartner_search_key,
bp.name AS bpartner_name,
bp.name2 AS bpartner_name2,
bp.created AS bpartner_created,
bp.updated as bpartner_updated,
bp.iscustomer AS bpartner_customer,
bp.isvendor AS bpartner_vendor,
bp.isemployee AS bpartner_employee,
bpg.value as bpartner_group_search_key,
bpg.name as bpartner_group_name,
bpg.description as bpartner_group_description,

pl.price_list_name as bpartner_customer_price_list_name,
pl.price_list_description as bpartner_customer_price_list_description,
pl.price_list_active as bpartner_customer_price_list_active,
pl.price_list_default as bpartner_customer_price_list_default,
pl.price_list_precision as bpartner_customer_price_list_precision,
pl.price_list_sales as bpartner_customer_price_list_sales,
pl.price_list_tax_included as bpartner_customer_price_list_tax_included,

vpl.price_list_name as bpartner_vendor_price_list_name,
vpl.price_list_description as bpartner_vendor_price_list_description,
vpl.price_list_active as bpartner_vendor_price_list_active,
vpl.price_list_default as bpartner_vendor_price_list_default,
vpl.price_list_precision as bpartner_vendor_price_list_precision,
vpl.price_list_sales as bpartner_vendor_price_list_sales,
vpl.price_list_tax_included as bpartner_vendor_price_list_tax_included

FROM c_bpartner bp
JOIN bi_client_cache c on bp.ad_client_id = c.client_id
JOIN bi_org_cache o on bp.ad_org_id = o.org_id
JOIN C_BP_Group bpg on bp.C_BP_Group_id = bpg.C_BP_Group_id
LEFT JOIN bi_price_list_cache pl on bp.m_pricelist_id = pl.price_list_id
LEFT JOIN bi_price_list_cache vpl on bp.po_pricelist_id = vpl.price_list_id
;
SELECT 'bp.'||column_name||',' as bpartner FROM information_schema.columns WHERE  table_name   = 'bi_bpartner';
--SELECT COUNT(*) as bp_count FROM bi_bpartner;
CREATE MATERIALIZED VIEW bi_bpartner_cache AS select * from bi_bpartner;
create unique index bi_bpartner_cache_uidx on bi_bpartner_cache (bpartner_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_bpartner_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_location AS
--{{{
SELECT
l.c_location_id as loc_id,
l.address1 AS loc_address1,
l.address2 AS loc_address2,
l.address3 AS loc_address3,
l.address4 AS loc_address4,
l.city AS loc_city,
l.regionname AS loc_state,
l.created as loc_created,
l.updated as loc_updated,
country.countrycode AS loc_country_code,
country.name AS loc_country_name
FROM c_location l
JOIN c_country country ON l.c_country_id = country.c_country_id
;
SELECT 'loc.'||column_name||',' as loc FROM information_schema.columns WHERE  table_name   = 'bi_location';
--SELECT COUNT(*) as loc_count FROM bi_location;
CREATE MATERIALIZED VIEW bi_location_cache AS select * from bi_location;
create unique index bi_location_cache_uidx on bi_location_cache (loc_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_location_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_partner_location AS
--{{{
SELECT
c.*,

bpl.c_bpartner_location_id as partner_location_id,

bp.bpartner_search_key,
bp.bpartner_name,
bp.bpartner_name2,
bp.bpartner_created,
bp.bpartner_updated,
bp.bpartner_customer,
bp.bpartner_vendor,
bp.bpartner_employee,

bpl.name AS location_name,
bpl.created as location_created,
bpl.updated as location_updated,

loc.loc_address1 as location_address1,
loc.loc_address2 as location_address2,
loc.loc_address3 as location_address3,
loc.loc_address4 as location_address4,
loc.loc_city as location_city,
loc.loc_state as location_state,
loc.loc_country_code as location_country_code,
loc.loc_country_name as location_country_name

FROM c_bpartner_location bpl
JOIN bi_bpartner_cache bp on bpl.c_bpartner_id = bp.bpartner_id
JOIN bi_client_cache c ON bpl.ad_client_id = c.client_id
JOIN bi_org_cache o on bpl.ad_org_id = o.org_id
join bi_location_cache loc on bpl.c_location_id = loc.loc_id
;
SELECT 'bploc.'||column_name||',' as bploc FROM information_schema.columns WHERE  table_name   = 'bi_partner_location';
--SELECT COUNT(*) as location_count FROM bi_partner_location;
CREATE MATERIALIZED VIEW bi_partner_location_cache AS select * from bi_partner_location;
create unique index bi_partner_location_cache_uidx on bi_partner_location_cache (partner_location_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_partner_location_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_user AS
--{{{
SELECT
c.*,
-- assuming no org needed
u.ad_user_id as user_id,
u.value as user_search_key,
u.name as user_name,
u.description as user_description,
u.email as user_email,
u.phone as user_phone,

bp.bpartner_search_key,
bp.bpartner_name,
bp.bpartner_name2,
bp.bpartner_created,
bp.bpartner_updated,
bp.bpartner_customer,
bp.bpartner_vendor,
bp.bpartner_employee,
bp.bpartner_group_search_key,
bp.bpartner_group_name,
bp.bpartner_group_description,

bploc.location_name as user_location_name,
bploc.location_created as user_location_created,
bploc.location_updated as user_location_updated,
bploc.location_address1 as user_location_address1,
bploc.location_address2 as user_location_address2,
bploc.location_address3 as user_location_address3,
bploc.location_address4 as user_location_address4,
bploc.location_city as user_location_city,
bploc.location_state as user_location_state,
bploc.location_country_code as user_location_country_code,
bploc.location_country_name as user_location_country_name

FROM ad_user u
JOIN bi_client_cache c on u.ad_client_id = c.client_id
LEFT JOIN bi_bpartner_cache bp on u.c_bpartner_id = bp.bpartner_id
LEFT JOIN bi_partner_location_cache bploc on u.c_bpartner_location_id = bploc.partner_location_id
;
SELECT 'u.'||column_name||',' as user FROM information_schema.columns WHERE  table_name   = 'bi_user';
--SELECT COUNT(*) as user_count FROM bi_user;
CREATE MATERIALIZED VIEW bi_user_cache AS select * from bi_user;
create unique index bi_user_cache_uidx on bi_user_cache (user_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_user_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_warehouse AS
--{{{
SELECT
c.*,
o.*,
w.m_warehouse_id as warehouse_id,
w.value as warehouse_search_key,
w.name as warehouse_name,
w.description as warehouse_description,
w.isactive as warehouse_active,
w.isintransit as warehouse_in_transit,
w.isdisallownegativeinv as warehouse_prevent_negative_inventory,
w.created as warehouse_created,
w.updated as warehouse_updated,

loc.loc_address1 as warehouse_loc_address1,
loc.loc_address2 as warehouse_loc_address2,
loc.loc_address3 as warehouse_loc_address3,
loc.loc_address4 as warehouse_loc_address4,
loc.loc_city as warehouse_loc_city,
loc.loc_state as warehouse_loc_state,
loc.loc_country_code as warehouse_loc_country_code,
loc.loc_country_name as warehouse_loc_country_name

FROM m_warehouse w
join bi_client_cache c on w.ad_client_id = c.client_id
join bi_org_cache o on w.ad_org_id = o.org_id
left join bi_location_cache loc on w.c_location_id = loc.loc_id
;
SELECT 'wh.'||column_name||',' as warehouse FROM information_schema.columns WHERE  table_name   = 'bi_warehouse';
--SELECT COUNT(*) as wh_count FROM bi_warehouse;
CREATE MATERIALIZED VIEW bi_warehouse_cache AS select * from bi_warehouse;
create unique index bi_warehouse_cache_uidx on bi_warehouse_cache (warehouse_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_warehouse_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_locator AS
--{{{
SELECT
wh.*,
locator.m_locator_id as locator_id,
locator.value as locator_search_key,
locator.x as locator_x,
locator.y as locator_y,
locator.z as locator_z,
locator.created as locator_created,
locator.updated as locator_updated,
mt.name as locator_type

FROM m_locator locator
JOIN bi_warehouse_cache wh on locator.m_warehouse_id = wh.warehouse_id
LEFT JOIN M_LocatorType mt on locator.M_LocatorType_id = mt.M_LocatorType_id
;
SELECT 'locator.'||column_name||',' as locator FROM information_schema.columns WHERE  table_name   = 'bi_locator';
--SELECT COUNT(*) as locator_count FROM bi_locator;
CREATE MATERIALIZED VIEW bi_locator_cache AS select * from bi_locator;
create unique index bi_locator_cache_uidx on bi_locator_cache (locator_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_locator_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_charge AS
--{{{
SELECT 
c.*,
chg.c_charge_id as charge_id,
chg.name AS charge_name,
chg.description AS charge_description,
chg.isactive as charge_active,
chg.created as charge_created,
chg.updated as charge_updated
FROM c_charge chg
JOIN bi_client_cache c on chg.ad_client_id=c.client_id;
SELECT 'chg.'||column_name||',' as charge FROM information_schema.columns WHERE  table_name   = 'bi_charge';
--SELECT COUNT(*) as charge_count FROM bi_charge;
CREATE MATERIALIZED VIEW bi_charge_cache AS select * from bi_charge;
create unique index bi_charge_cache_uidx on bi_charge_cache (charge_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_charge_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_product AS
--{{{
SELECT
c.*,
p.m_product_id as product_id,
p.value as product_search_key,
p.created as product_created,
p.updated as product_updated,
p.name as product_name,
p.description as product_description,
p.documentnote as product_document_note,
p.isactive as product_active,
prodtype.name as product_type,
pc.name as product_category_name,
uom.uom_name as product_uom_name
from m_product p
join AD_Ref_List prodtype on p.producttype = prodtype.value AND prodtype.AD_Reference_ID=270
join m_product_category pc on p.m_product_category_id = pc.m_product_category_id
join bi_uom_cache uom on p.c_uom_id = uom.uom_id
join bi_client_cache c on p.ad_client_id = c.client_id
;
SELECT 'prod.'||column_name||',' as product FROM information_schema.columns WHERE  table_name   = 'bi_product';
--SELECT COUNT(*) as product_count FROM bi_product;
CREATE MATERIALIZED VIEW bi_product_cache AS select * from bi_product;
create unique index bi_product_cache_uidx on bi_product_cache (product_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_product_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_channel AS
--{{{
SELECT
c.*,
channel.c_channel_id as channel_id,
channel.name as channel_name,
channel.description as channel_description
FROM c_channel channel
JOIN bi_client_cache c on channel.ad_client_id = c.client_id
;
SELECT 'channel.'||column_name||',' as channel FROM information_schema.columns WHERE  table_name = 'bi_channel';
--SELECT COUNT(*) as channel_count FROM bi_channel;
CREATE MATERIALIZED VIEW bi_channel_cache as select * from bi_channel;
create unique index bi_channel_cache_uidx on bi_channel_cache (channel_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_channel_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_campaign AS
--{{{
SELECT
c.*,
campaign.c_campaign_id as campaign_id,
campaign.value as campaign_search_key,
campaign.name as campaign_name,
campaign.value||'_'||campaign.name as campaign_search_key_name,
campaign.description as campaign_description,
campaign.startdate as campaign_startdate,
campaign.enddate as campaign_enddate,
campaign.costs as campaign_costs,
campaign.issummary as campaign_summary,
channel.channel_name as campaign_channel_name,
channel.channel_description as campaign_channel_description
FROM c_campaign campaign
JOIN bi_client_cache c on campaign.ad_client_id = c.client_id
JOIN bi_channel_cache channel on campaign.c_channel_id = channel.channel_id
;
SELECT 'campaign.'||column_name||',' as campaign FROM information_schema.columns WHERE  table_name = 'bi_campaign';
--SELECT COUNT(*) as campaign_count FROM bi_campaign;
CREATE MATERIALIZED VIEW bi_campaign_cache as select * from bi_campaign;
create unique index bi_campaign_cache_uidx on bi_campaign_cache (campaign_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_campaign_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_activity AS
--{{{
SELECT
c.*,
activity.c_activity_id as activity_id,
activity.value as activity_search_key,
activity.name as activity_name,
activity.value||'_'||activity.name as activity_search_key_name,
activity.description as activity_description,
activity.issummary as activity_summary,
activity.help as activity_help
FROM c_activity activity
JOIN bi_client_cache c on activity.ad_client_id = c.client_id
;
SELECT 'activity.'||column_name||',' as activity FROM information_schema.columns WHERE  table_name = 'bi_activity';
--SELECT COUNT(*) as activity_count FROM bi_activity;
CREATE MATERIALIZED VIEW bi_activity_cache as select * from bi_activity;
create unique index bi_activity_cache_uidx on bi_activity_cache (activity_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_activity_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_department AS
--{{{
SELECT
c.*,
department.c_activity_id as department_id,
department.value as department_search_key,
department.name as department_name,
department.value||'_'||department.name as department_search_key_name,
department.description as department_description,
department.issummary as department_summary,
department.help as department_help
FROM c_activity department
JOIN bi_client_cache c on department.ad_client_id = c.client_id
;
SELECT 'department.'||column_name||',' as department FROM information_schema.columns WHERE  table_name = 'bi_department';
--SELECT COUNT(*) as department_count FROM bi_department;
CREATE MATERIALIZED VIEW bi_department_cache as select * from bi_department;
create unique index bi_department_cache_uidx on bi_department_cache (department_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_department_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_project AS
--{{{
SELECT
c.*,
o.*,
proj.c_project_id as project_id,
proj.value as project_search_key,
proj.name as project_name,
proj.description as project_description,
proj.isactive as project_active,
proj.issummary as project_summary,
proj.note as project_note,
proj.datecontract as project_date_contract,
proj.datefinish as project_date_finish,
proj.created as project_created,
proj.updated as project_updated,
level.name as project_line_level,

bp.bpartner_search_key as project_bpartner_search_key,
bp.bpartner_name as project_bpartner_name,
bp.bpartner_name2 as project_bpartner_name2,
bp.bpartner_created as project_bpartner_created,
bp.bpartner_updated as project_bpartner_updated,
bp.bpartner_customer as project_bpartner_customer,
bp.bpartner_vendor as project_bpartner_vendor,
bp.bpartner_employee as project_bpartner_employee,
bp.bpartner_group_search_key as project_bpartner_group_search_key,
bp.bpartner_group_name as project_bpartner_group_name,
bp.bpartner_group_description as project_bpartner_group_description,

bpsr.bpartner_search_key as project_agent_search_key,
bpsr.bpartner_name as project_agent_name,
bpsr.bpartner_name2 as project_agent_name2,
bpsr.bpartner_created as project_agent_created,
bpsr.bpartner_updated as project_agent_updated,
bpsr.bpartner_customer as project_agent_customer,
bpsr.bpartner_vendor as project_agent_vendor,
bpsr.bpartner_employee as project_agent_employee,
bpsr.bpartner_group_search_key as project_agent_group_search_key,
bpsr.bpartner_group_name as project_agent_group_name,
bpsr.bpartner_group_description as project_agent_group_description,

wh.warehouse_search_key as project_warehouse_search_key,
wh.warehouse_name as project_warehouse_name,
wh.warehouse_description as project_warehouse_description,
wh.warehouse_active as project_warehouse_active,
wh.warehouse_in_transit as project_warehouse_in_transit,
wh.warehouse_prevent_negative_inventory as project_warehouse_prevent_negative_inventory,
wh.warehouse_loc_address1 as project_warehouse_loc_address1,
wh.warehouse_loc_address2 as project_warehouse_loc_address2,
wh.warehouse_loc_address3 as project_warehouse_loc_address3,
wh.warehouse_loc_address4 as project_warehouse_loc_address4,
wh.warehouse_loc_city as project_warehouse_loc_city,
wh.warehouse_loc_state as project_warehouse_loc_state,
wh.warehouse_loc_country_code as project_warehouse_loc_country_code,
wh.warehouse_loc_country_name as project_warehouse_loc_country_name,

-- price list version
plv.price_list_name as project_price_list_name,
plv.price_list_description as project_price_list_description,
plv.price_list_active as project_price_list_active,
plv.price_list_default as project_price_list_default,
plv.price_list_precision as project_price_list_precision,
plv.price_list_sales as project_price_list_sales,
plv.price_list_tax_included as project_price_list_tax_included,
plv.price_list_enforce_limit as project_price_list_enforce_limit,
plv.price_list_created as project_price_list_created,
plv.price_list_updated as project_price_list_updated,
plv.price_list_currency_iso_code as project_price_list_currency_iso_code,
plv.price_list_currency_symbol as project_price_list_currency_symbol,
plv.price_list_currency_description as project_price_list_currency_description,
plv.price_list_version_name as project_price_list_version_name,
plv.price_list_version_description as project_price_list_version_description,
plv.price_list_version_created as project_price_list_version_created,
plv.price_list_version_updated as project_price_list_version_updated,
plv.price_list_version_active as project_price_list_version_active

FROM c_project proj
JOIN bi_client_cache c on proj.ad_client_id = c.client_id
JOIN bi_org_cache o on proj.ad_org_id = o.org_id
LEFT JOIN bi_bpartner_cache bp on proj.c_bpartner_id = bp.bpartner_id
LEFT JOIN bi_bpartner_cache bpsr on proj.c_bpartnersr_id = bp.bpartner_id
LEFT JOIN bi_warehouse_cache wh on proj.m_warehouse_id = wh.warehouse_id
LEFT JOIN AD_Ref_List level on proj.projectlinelevel = level.value AND level.AD_Reference_ID=384
LEFT JOIN bi_price_list_version_cache plv on proj.m_pricelist_version_id = plv.price_list_version_id
;
SELECT 'proj.'||column_name||',' as project FROM information_schema.columns WHERE  table_name   = 'bi_project';
--SELECT COUNT(*) as project_count FROM bi_project;
CREATE MATERIALIZED VIEW bi_project_cache AS select * from bi_project;
create unique index bi_project_cache_uidx on bi_project_cache (project_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_project_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_order AS
--{{{
SELECT
c.*,
o.*,
ord.c_order_id as order_id,
ord.documentno as Order_document_number,
dt.name as order_document_type,
dt.c_doctype_id as order_document_type_id, --needed for orderline level calculations -- should not be shown to user
ord.poreference as order_order_reference,
ord.description as order_description,
ord.datepromised as order_date_promised,
ord.dateordered as Order_date_ordered,
delrule.name as order_delivery_rule,
invrule.name as order_invoice_rule,
ord.priorityrule as order_priority,

ord.grandtotal as order_total_grand_raw,
doctypemultiplier_birp(dt.c_doctype_id)*ord.grandtotal as order_total_grand_all,
ord.totallines as order_total_lines_raw,
ord.totallines as order_total_lines_all,
ord.issotrx as Order_Sales_Transaction,
ord.docstatus as Order_document_status,
ord.created as order_created,
ord.updated as order_updated,

bp.bpartner_search_key as order_ship_bpartner_search_key,
bp.bpartner_name as order_ship_bpartner_name,
bp.bpartner_name2 as order_ship_bpartner_name2,
bp.bpartner_created as order_ship_bpartner_created,
bp.bpartner_updated as order_ship_bpartner_updated,
bp.bpartner_customer as order_ship_bpartner_customer,
bp.bpartner_vendor as order_ship_bpartner_vendor,
bp.bpartner_employee as order_ship_bpartner_employee,
bp.bpartner_group_search_key as order_ship_bpartner_group_search_key,
bp.bpartner_group_name as order_ship_bpartner_group_name,
bp.bpartner_group_description as order_ship_bpartner_group_description,

bploc.location_name as order_ship_location_name,
bploc.location_address1 as order_ship_location_address1,
bploc.location_address2 as order_ship_location_address2,
bploc.location_address3 as order_ship_location_address3,
bploc.location_address4 as order_ship_location_address4,
bploc.location_city as order_ship_location_city,
bploc.location_state as order_ship_location_state,
bploc.location_country_code as order_ship_location_country_code,
bploc.location_country_name as order_ship_location_country_name,

bpinv.bpartner_search_key as order_invoice_bpartner_search_key,
bpinv.bpartner_name as order_invoice_bpartner_name,
bpinv.bpartner_name2 as order_invoice_bpartner_name2,
bpinv.bpartner_created as order_invoice_bpartner_created,
bpinv.bpartner_updated as order_invoice_bpartner_updated,
bpinv.bpartner_customer as order_invoice_bpartner_customer,
bpinv.bpartner_vendor as order_invoice_bpartner_vendor,
bpinv.bpartner_employee as order_invoice_bpartner_employee,
bpinv.bpartner_group_search_key as order_invoice_bpartner_group_search_key,
bpinv.bpartner_group_name as order_invoice_bpartner_group_name,
bpinv.bpartner_group_description as order_invoice_bpartner_group_description,

bplocinv.location_name as order_invoice_location_name,
bplocinv.location_address1 as order_invoice_location_address1,
bplocinv.location_address2 as order_invoice_location_address2,
bplocinv.location_address3 as order_invoice_location_address3,
bplocinv.location_address4 as order_invoice_location_address4,
bplocinv.location_city as order_invoice_location_city,
bplocinv.location_state as order_invoice_location_state,
bplocinv.location_country_code as order_invoice_location_country_code,
bplocinv.location_country_name as order_invoice_location_country_name,

wh.warehouse_search_key as order_warehouse_search_key,
wh.warehouse_name as order_warehouse_name,
wh.warehouse_description as order_warehouse_description,
wh.warehouse_active as order_warehouse_active,
wh.warehouse_in_transit as order_warehouse_in_transit,
wh.warehouse_prevent_negative_inventory as order_warehouse_prevent_negative_inventory,
wh.warehouse_loc_address1 as order_warehouse_loc_address1,
wh.warehouse_loc_address2 as order_warehouse_loc_address2,
wh.warehouse_loc_address3 as order_warehouse_loc_address3,
wh.warehouse_loc_address4 as order_warehouse_loc_address4,
wh.warehouse_loc_city as order_warehouse_loc_city,
wh.warehouse_loc_state as order_warehouse_loc_state,
wh.warehouse_loc_country_code as order_warehouse_loc_country_code,
wh.warehouse_loc_country_name as order_warehouse_loc_country_name,

pl.price_list_name as order_price_list_name,
pl.price_list_description as order_price_list_description,
pl.price_list_active as order_price_list_active,
pl.price_list_default as order_price_list_default,
pl.price_list_precision as order_price_list_precision,
pl.price_list_sales as order_price_list_sales,
pl.price_list_tax_included as order_price_list_tax_included,

activity.activity_search_key as order_activity_search_key,
activity.activity_name as order_activity_name,
activity.activity_search_key_name as order_activity_search_key_name,
activity.activity_description as order_activity_description,
activity.activity_summary as order_activity_summary,
activity.activity_help as order_activity_help,
activity.activity_id as order_activity_id,

campaign.campaign_search_key as order_campaign_search_key,
campaign.campaign_name as order_campaign_name,
campaign.campaign_search_key_name as order_campaign_search_key_name,
campaign.campaign_description as order_campaign_description,
campaign.campaign_startdate as order_campaign_startdate,
campaign.campaign_enddate as order_campaign_enddate,
campaign.campaign_costs as order_campaign_costs,
campaign.campaign_summary as order_campaign_summary,
campaign.campaign_channel_name as order_campaign_channel_name,
campaign.campaign_channel_description as order_campaign_channel_description,
campaign.campaign_id as order_campaign_id,

curr.currency_iso_code as order_currency_iso_code,
curr.currency_symbol as order_currency_symbol,
curr.currency_description as order_currency_description

from c_order ord
join bi_bpartner_cache bp on ord.c_bpartner_id = bp.bpartner_id
join bi_bpartner_cache bpinv on ord.bill_bpartner_id = bpinv.bpartner_id
join bi_partner_location_cache bploc on ord.c_bpartner_location_id = bploc.partner_location_id
join bi_partner_location_cache bplocinv on ord.bill_location_id = bplocinv.partner_location_id
join bi_client_cache c on ord.ad_client_id = c.client_id
join bi_org_cache o on ord.ad_org_id = o.org_id
join c_doctype dt on ord.c_doctypetarget_id = dt.c_doctype_id
left join AD_Ref_List delrule on ord.deliveryrule = delrule.value and delrule.AD_Reference_ID=151
left join AD_Ref_List invrule on ord.invoicerule = invrule.value and invrule.AD_Reference_ID=150
left join bi_warehouse_cache wh on ord.m_warehouse_id = wh.warehouse_id
left join bi_price_list_cache pl on ord.m_pricelist_id = pl.price_list_id
left join bi_activity_cache activity on ord.c_activity_id = activity.activity_id
left join bi_campaign_cache campaign on ord.c_campaign_id = campaign.campaign_id
left join bi_currency_cache curr on ord.c_currency_id = curr.currency_id
;
SELECT 'ord.'||column_name||',' as order FROM information_schema.columns WHERE  table_name   = 'bi_order';
--SELECT COUNT(*) as order_count FROM bi_order;
CREATE MATERIALIZED VIEW bi_order_cache AS select * from bi_order;
create unique index bi_order_cache_uidx on bi_order_cache (order_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_order_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_project_phase AS
--{{{
SELECT
proj.*,
projph.c_projectphase_id as project_phase_id,
projph.seqno as project_phase_sequence_number,
projph.name as project_phase_name,
projph.description as project_phase_description,
projph.isactive as project_phase_active,
projph.iscomplete as project_phase_complete,
projph.startdate as project_phase_date_start,
projph.enddate as project_phase_date_end,
invoicerule.name as project_phase_invoice_rule,
projph.plannedamt as project_phase_total_planned,
projph.qty as project_phase_quantity,

ord.order_document_number as project_phase_order_document_number,
ord.order_document_type as project_phase_order_document_type,
ord.order_document_type_id as project_phase_order_document_type_id,
ord.order_order_reference as project_phase_order_order_reference,
ord.order_description as project_phase_order_description,
ord.order_date_promised as project_phase_order_date_promised,
ord.order_date_ordered as project_phase_order_date_ordered,
ord.order_delivery_rule as project_phase_order_delivery_rule,
ord.order_invoice_rule as project_phase_order_invoice_rule,
ord.order_priority as project_phase_order_priority,
ord.order_total_grand_raw as project_phase_order_total_grand_raw,
ord.order_total_grand_all as project_phase_order_total_grand_all,
ord.order_total_lines_raw as project_phase_order_total_lines_raw,
ord.order_total_lines_all as project_phase_order_total_lines_all,
ord.order_sales_transaction as project_phase_order_sales_transaction,
ord.order_document_status as project_phase_order_document_status,
ord.order_created as project_phase_order_created,
ord.order_updated as project_phase_order_updated,
ord.order_ship_bpartner_search_key as project_phase_order_ship_bpartner_search_key,
ord.order_ship_bpartner_name as project_phase_order_ship_bpartner_name,

prod.product_search_key as project_phase_product_search_key,
prod.product_created as project_phase_product_created,
prod.product_updated as project_phase_product_updated,
prod.product_name as project_phase_product_name,
prod.product_description as project_phase_product_description,
prod.product_document_note as project_phase_product_document_note,
prod.product_active as project_phase_product_active,
prod.product_type as project_phase_product_type,
prod.product_category_name as project_phase_product_category_name,
prod.product_uom_name as project_phase_product_uom_name

FROM c_projectphase projph
JOIN bi_project_cache proj on projph.c_project_id = proj.project_id
LEFT JOIN AD_Ref_List invoicerule on projph.projinvoicerule = invoicerule.value and AD_Reference_ID=383
LEFT JOIN bi_order_cache ord on projph.c_order_id = ord.order_id
LEFT JOIN bi_product_cache prod on projph.m_product_id = prod.product_id
;
SELECT 'projph.'||column_name||',' as project_phase FROM information_schema.columns WHERE  table_name   = 'bi_project_phase';
--SELECT COUNT(*) as project_phase_count FROM bi_project_phase;
CREATE MATERIALIZED VIEW bi_project_phase_cache AS select * from bi_project_phase;
create unique index bi_project_phase_cache_uidx on bi_project_phase_cache (project_phase_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_project_phase_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_order_line AS
--{{{
SELECT 
o.*,
ol.c_orderline_id as order_line_id,
ol.line as order_line_lineno,
ol.qtyordered as order_line_qty_ordered,
ol.qtyentered as order_line_qty_entered,
ol.qtyinvoiced as order_line_qty_invoiced,
ol.qtydelivered as order_line_qty_delivered,
ol.description as order_line_description,
ol.priceentered as order_line_price_entered,
ol.linenetamt as order_line_total_raw,
doctypemultiplier_birp(o.order_document_type_id)*ol.linenetamt as order_line_total_all,
ol.created as order_line_created,
ol.updated as order_line_updated,

prod.product_search_key as order_line_product_search_key,
prod.product_name as order_line_product_name,
prod.product_description as order_line_product_description,
prod.product_document_note as order_line_product_document_note,
prod.product_category_name as order_line_product_category_name,

uom.uom_name as order_line_uom_name,
uom.uom_search_key as order_line_uom_search_key,

chg.charge_name as order_line_charge_name,
chg.charge_description as order_line_charge_description,

t.tax_name as order_line_tax_name,
t.tax_description as order_line_tax_description,
t.tax_active as order_line_tax_active,
t.tax_rate as order_line_tax_rate,
t.tax_indicator as order_line_tax_indicator ,
t.tax_category_name as order_line_tax_category_name,
t.tax_category_description as order_line_tax_category_description,

bploc.location_name as order_line_location_name,
bploc.location_created as order_line_location_created,
bploc.location_updated as order_line_location_updated,
bploc.location_address1 as order_line_location_address1,
bploc.location_address2 as order_line_location_address2,
bploc.location_address3 as order_line_location_address3,
bploc.location_address4 as order_line_location_address4,
bploc.location_city as order_line_location_city,
bploc.location_state as order_line_location_state,
bploc.location_country_code as order_line_location_country_code,
bploc.location_country_name as order_line_location_country_name,

activity.activity_search_key as order_line_activity_search_key,
activity.activity_name as order_line_activity_name,
activity.activity_search_key_name as order_line_activity_search_key_name,
activity.activity_description as order_line_activity_description,
activity.activity_summary as order_line_activity_summary,
activity.activity_help as order_line_activity_help,

campaign.campaign_search_key as order_line_campaign_search_key,
campaign.campaign_name as order_line_campaign_name,
campaign.campaign_search_key_name as order_line_campaign_search_key_name,
campaign.campaign_description as order_line_campaign_description,
campaign.campaign_startdate as order_line_campaign_startdate,
campaign.campaign_enddate as order_line_campaign_enddate,
campaign.campaign_costs as order_line_campaign_costs,
campaign.campaign_summary as order_line_campaign_summary,
campaign.campaign_channel_name as order_line_campaign_channel_name,
campaign.campaign_channel_description as order_line_campaign_channel_description

FROM c_orderline ol
JOIN bi_order_cache o ON ol.c_order_id = o.order_id
LEFT JOIN bi_product_cache prod on ol.m_product_id = prod.product_id
LEFT JOIN bi_charge_cache chg ON ol.c_charge_id = chg.charge_id
JOIN bi_uom_cache uom on ol.c_uom_id = uom.uom_id
JOIN bi_partner_location_cache bploc on ol.c_bpartner_location_id = bploc.partner_location_id
LEFT JOIN bi_tax_cache t on ol.c_tax_id = t.tax_id
left join bi_activity_cache activity on coalesce(ol.c_activity_id, o.order_activity_id) = activity.activity_id
left join bi_campaign_cache campaign on coalesce(ol.c_campaign_id, o.order_campaign_id) = campaign.campaign_id
;
SELECT 'orderline.'||column_name||',' as orderline FROM information_schema.columns WHERE  table_name   = 'bi_order_line';
--SELECT COUNT(*) as order_line_count FROM bi_order_line;
CREATE MATERIALIZED VIEW bi_order_line_cache AS select * from bi_order_line;
create unique index bi_order_line_cache_uidx on bi_order_line_cache (order_line_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_order_line_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_invoice AS
--{{{
SELECT
c.*,
o.*,
inv.c_invoice_id as invoice_id,
inv.documentno as Invoice_document_number,
dt.name as invoice_document_type,
dt.c_doctype_id as invoice_document_type_id, --hide this from the user, this is used at invoice line total calculations
inv.description as invoice_description,
inv.poreference as invoice_order_reference,
inv.grandtotal AS Invoice_total_grand_raw,
doctypemultiplier_bicm(dt.c_doctype_id)*inv.grandtotal AS invoice_total_grand_adj,
doctypemultiplier_bicm(dt.c_doctype_id)*doctypemultiplier_birp(dt.c_doctype_id)*inv.grandtotal AS invoice_total_grand_all,
inv.totallines as invoice_total_lines_raw,
doctypemultiplier_bicm(dt.c_doctype_id)*inv.totallines as invoice_total_lines_adj,
doctypemultiplier_bicm(dt.c_doctype_id)*doctypemultiplier_birp(dt.c_doctype_id)*inv.totallines as invoice_total_lines_all,
inv.issotrx as Invoice_Sales_Transaction,
inv.docstatus as Invoice_document_status,
inv.dateinvoiced as invoice_date,
inv.dateacct as invoice_date_account,
inv.created as invoice_created,
inv.updated as invoice_updated,

bp.bpartner_search_key as invoice_bpartner_search_key,
bp.bpartner_name as invoice_bpartner_name,
bp.bpartner_name2 as invoice_bpartner_name2,
bp.bpartner_created as invoice_bpartner_created,
bp.bpartner_customer as invoice_bpartner_customer,
bp.bpartner_vendor as invoice_bpartner_vendor,
bp.bpartner_employee as invoice_bpartner_employee,
bp.bpartner_group_search_key as invoice_bpartner_group_search_key,
bp.bpartner_group_name as invoice_bpartner_group_name,
bp.bpartner_group_description as invoice_bpartner_group_description,

bpl.location_name as invoice_location_name,
bpl.location_address1 as invoice_location_address1,
bpl.location_address2 as invoice_location_address2,
bpl.location_address3 as invoice_location_address3,
bpl.location_address4 as invoice_location_address4,
bpl.location_city as invoice_location_city,
bpl.location_state as invoice_location_state,
bpl.location_country_code as invoice_location_country_code,
bpl.location_country_name as invoice_location_country_name,

ord.order_ship_bpartner_search_key,
ord.order_ship_bpartner_name,
ord.order_ship_bpartner_name2,
ord.order_ship_bpartner_created,
ord.order_ship_bpartner_updated,
ord.order_ship_bpartner_customer,
ord.order_ship_bpartner_vendor,
ord.order_ship_bpartner_employee,
ord.order_ship_bpartner_group_search_key,
ord.order_ship_bpartner_group_name,
ord.order_ship_bpartner_group_description,

ord.order_ship_location_name,
ord.order_ship_location_address1,
ord.order_ship_location_address2,
ord.order_ship_location_address3,
ord.order_ship_location_address4,
ord.order_ship_location_city,
ord.order_ship_location_state,
ord.order_ship_location_country_code,
ord.order_ship_location_country_name,

pl.price_list_name as invoice_price_list_name,
pl.price_list_description as invoice_price_list_description,
pl.price_list_active as invoice_price_list_active,
pl.price_list_default as invoice_price_list_default,
pl.price_list_precision as invoice_price_list_precision,
pl.price_list_sales as invoice_price_list_sales,
pl.price_list_tax_included as invoice_price_list_tax_included,

activity.activity_search_key as invoice_activity_search_key,
activity.activity_name as invoice_activity_name,
activity.activity_search_key_name as invoice_activity_search_key_name,
activity.activity_description as invoice_activity_description,
activity.activity_summary as invoice_activity_summary,
activity.activity_help as invoice_activity_help,
activity.activity_id as invoice_activity_id,

campaign.campaign_search_key as invoice_campaign_search_key,
campaign.campaign_name as invoice_campaign_name,
campaign.campaign_search_key_name as invoice_campaign_search_key_name,
campaign.campaign_description as invoice_campaign_description,
campaign.campaign_startdate as invoice_campaign_startdate,
campaign.campaign_enddate as invoice_campaign_enddate,
campaign.campaign_costs as invoice_campaign_costs,
campaign.campaign_summary as invoice_campaign_summary,
campaign.campaign_channel_name as invoice_campaign_channel_name,
campaign.campaign_channel_description as invoice_campaign_channel_description,
campaign.campaign_id as invoice_campaign_id,

curr.currency_iso_code as invoice_currency_iso_code,
curr.currency_symbol as invoice_currency_symbol,
curr.currency_description as invoice_currency_description

FROM c_invoice inv
JOIN bi_bpartner_cache bp ON inv.c_bpartner_id = bp.bpartner_id
JOIN bi_partner_location_cache bpl ON inv.c_bpartner_location_id = bpl.partner_location_id
JOIN bi_client_cache c ON inv.ad_client_id = c.client_id
JOIN bi_org_cache o ON inv.ad_org_id = o.org_id
JOIN c_doctype dt ON inv.c_doctypetarget_id = dt.c_doctype_id
LEFT JOIN bi_order_cache ord on inv.c_order_id = ord.order_id
LEFT JOIN bi_price_list_cache pl on inv.m_pricelist_id = pl.price_list_id
left join bi_activity_cache activity on inv.c_activity_id = activity.activity_id
left join bi_campaign_cache campaign on inv.c_campaign_id = campaign.campaign_id
LEFT JOIN bi_currency_cache curr on inv.c_currency_id = curr.currency_id
;
SELECT 'invoice.'||column_name||',' as invoice FROM information_schema.columns WHERE  table_name   = 'bi_invoice';
--SELECT COUNT(*) as invoice_count FROM bi_invoice;
CREATE MATERIALIZED VIEW bi_invoice_cache AS select * from bi_invoice;
create unique index bi_invoice_cache_uidx on bi_invoice_cache (invoice_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_invoice_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_invoice_line AS
--{{{
SELECT 
c.*,
o.*,
invoice.invoice_document_number,
invoice.invoice_document_type,
invoice.invoice_description,
invoice.invoice_order_reference,
invoice.invoice_total_grand_raw,
invoice.invoice_total_grand_adj,
invoice.invoice_total_grand_all,
invoice.invoice_total_lines_raw,
invoice.invoice_total_lines_adj,
invoice.invoice_total_lines_all,
invoice.invoice_sales_transaction,
invoice.invoice_document_status,
invoice.invoice_date,
invoice.invoice_date_account,
invoice.invoice_created,
invoice.invoice_updated,
invoice.invoice_bpartner_search_key,
invoice.invoice_bpartner_name,
invoice.invoice_bpartner_name2,
invoice.invoice_bpartner_created,
invoice.invoice_bpartner_customer,
invoice.invoice_bpartner_vendor,
invoice.invoice_bpartner_employee,
invoice.invoice_bpartner_group_search_key,
invoice.invoice_bpartner_group_name,
invoice.invoice_bpartner_group_description,
invoice.invoice_location_name,
invoice.invoice_location_address1,
invoice.invoice_location_address2,
invoice.invoice_location_address3,
invoice.invoice_location_address4,
invoice.invoice_location_city,
invoice.invoice_location_state,
invoice.invoice_location_country_code,
invoice.invoice_location_country_name,
invoice.invoice_price_list_name,
invoice.invoice_price_list_description,
invoice.invoice_price_list_active,
invoice.invoice_price_list_default,
invoice.invoice_price_list_precision,
invoice.invoice_price_list_sales,
invoice.invoice_price_list_tax_included,
invoice.invoice_currency_iso_code,
invoice.invoice_currency_symbol,
invoice.invoice_currency_description,

invoice.order_ship_bpartner_search_key,
invoice.order_ship_bpartner_name,
invoice.order_ship_bpartner_name2,
invoice.order_ship_bpartner_created,
invoice.order_ship_bpartner_updated,
invoice.order_ship_bpartner_customer,
invoice.order_ship_bpartner_vendor,
invoice.order_ship_bpartner_employee,
invoice.order_ship_bpartner_group_search_key,
invoice.order_ship_bpartner_group_name,
invoice.order_ship_bpartner_group_description,
invoice.order_ship_location_name,
invoice.order_ship_location_address1,
invoice.order_ship_location_address2,
invoice.order_ship_location_address3,
invoice.order_ship_location_address4,
invoice.order_ship_location_city,
invoice.order_ship_location_state,
invoice.order_ship_location_country_code,
invoice.order_ship_location_country_name,

il.c_invoiceline_id as invoice_line_id,
il.line as invoice_line_lineno,
il.description as invoice_line_description,
il.qtyinvoiced as invoice_line_qty_invoiced, 
il.priceactual as invoice_line_price_actual,
il.taxamt as invoice_line_tax_total_raw,
doctypemultiplier_bicm(invoice.invoice_document_type_id)*il.taxamt as invoice_line_tax_total_adj,
doctypemultiplier_bicm(invoice.invoice_document_type_id)*doctypemultiplier_birp(invoice.invoice_document_type_id)*il.taxamt as invoice_line_tax_total_all,
il.linetotalamt as invoice_line_total_grand_raw,
doctypemultiplier_bicm(invoice.invoice_document_type_id)*il.linetotalamt as invoice_line_total_grand_adj,
doctypemultiplier_bicm(invoice.invoice_document_type_id)*doctypemultiplier_birp(invoice.invoice_document_type_id)*il.linetotalamt as invoice_line_total_grand_all,
il.linenetamt as invoice_line_total_line_raw, 
doctypemultiplier_bicm(invoice.invoice_document_type_id)*il.linenetamt as invoice_line_total_line_adj, 
doctypemultiplier_bicm(invoice.invoice_document_type_id)*doctypemultiplier_birp(invoice.invoice_document_type_id)*il.linenetamt as invoice_line_total_line_all, 
il.created as invoice_line_created,
il.updated as invoice_line_updated,

prod.product_search_key as invoice_line_product_search_key,
prod.product_created as invoice_line_product_created,
prod.product_updated as invoice_line_product_updated,
prod.product_name as invoice_line_product_name,
prod.product_description as invoice_line_product_description,
prod.product_document_note as invoice_line_product_document_note,
prod.product_active as invoice_line_product_active,
prod.product_type as invoice_line_product_type,
prod.product_category_name as invoice_line_product_category_name,

chg.charge_name as invoice_line_charge_name,
chg.charge_description as invoice_line_charge_description,
chg.charge_active as invoice_line_charge_active,
chg.charge_created as invoice_line_charge_created,
chg.charge_updated as invoice_line_charge_updated,

t.tax_name as invoice_line_tax_name,
t.tax_description as invoice_line_tax_description,
t.tax_active as invoice_line_tax_active,
t.tax_rate as invoice_line_tax_rate,
t.tax_indicator as invoice_line_tax_indicator,
t.tax_category_name as invoice_line_tax_category_name,
t.tax_category_description as invoice_line_tax_category_description,

activity.activity_search_key as invoice_line_activity_search_key,
activity.activity_name as invoice_line_activity_name,
activity.activity_search_key_name as invoice_line_activity_search_key_name,
activity.activity_description as invoice_line_activity_description,
activity.activity_summary as invoice_line_activity_summary,
activity.activity_help as invoice_line_activity_help,

campaign.campaign_search_key as invoice_line_campaign_search_key,
campaign.campaign_name as invoice_line_campaign_name,
campaign.campaign_search_key_name as invoice_line_campaign_search_key_name,
campaign.campaign_description as invoice_line_campaign_description,
campaign.campaign_startdate as invoice_line_campaign_startdate,
campaign.campaign_enddate as invoice_line_campaign_enddate,
campaign.campaign_costs as invoice_line_campaign_costs,
campaign.campaign_summary as invoice_line_campaign_summary,
campaign.campaign_channel_name as invoice_line_campaign_channel_name,
campaign.campaign_channel_description as invoice_line_campaign_channel_description,

uom.uom_name as invoice_line_uom_name,
uom.uom_search_key as invoice_line_uom_search_key

FROM c_invoiceline il 
JOIN bi_client_cache c on il.ad_client_id = c.client_id
JOIN bi_org_cache o on il.ad_org_id = o.org_id
JOIN bi_invoice_cache invoice ON il.c_invoice_id = invoice.invoice_id
LEFT JOIN bi_product_cache prod ON il.m_product_id = prod.product_id
LEFT JOIN bi_uom_cache uom ON il.c_uom_id = uom.uom_id
left join bi_activity_cache activity on coalesce(il.c_activity_id, invoice.invoice_activity_id) = activity.activity_id
left join bi_campaign_cache campaign on coalesce(il.c_campaign_id, invoice.invoice_campaign_id) = campaign.campaign_id
LEFT JOIN bi_charge_cache chg ON il.c_charge_id = chg.charge_id
LEFT JOIN bi_tax_cache t on il.c_tax_id = t.tax_id
;
SELECT 'invoiceline.'||column_name||',' as invoiceline FROM information_schema.columns WHERE  table_name   = 'bi_invoice_line';
--SELECT COUNT(*) as invoice_line_count FROM bi_invoice_line;
CREATE MATERIALIZED VIEW bi_invoice_line_cache AS select * from bi_invoice_line;
create unique index bi_invoice_line_cache_uidx on bi_invoice_line_cache (invoice_line_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_invoice_line_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_inout AS
--{{{
SELECT 
c.*,
o.*,
io.m_inout_id as inout_id,
io.issotrx AS InOut_Sales_Transaction,
io.documentno AS InOut_document_number,
io.docaction AS InOut_document_action,
io.docstatus AS InOut_document_status,
dt.name AS InOut_doctype_name,
io.description AS InOut_description,
io.dateordered AS InOut_date_ordered,
io.movementdate as inout_movement_date,
io.created as inout_created,
io.updated as inout_updated,
bp.bpartner_search_key as inout_bpartner_search_key,
bp.bpartner_name as inout_bpartner_name,
bp.bpartner_name2 as inout_bpartner_name2,
bp.bpartner_created as inout_bpartner_created,
bp.bpartner_customer as inout_bpartner_customer,
bp.bpartner_vendor as inout_bpartner_vendor,
bp.bpartner_employee as inout_bpartner_employee,
bp.bpartner_group_search_key as inout_bpartner_group_search_key,
bp.bpartner_group_name as inout_bpartner_group_name,
bp.bpartner_group_description as inout_bpartner_group_description,

bpl.location_name as inout_location_name,
bpl.location_address1 as inout_location_address1,
bpl.location_address2 as inout_location_address2,
bpl.location_address3 as inout_location_address3,
bpl.location_address4 as inout_location_address4,
bpl.location_city as inout_location_city,
bpl.location_state as inout_location_state,
bpl.location_country_code as inout_location_country_code,
bpl.location_country_name as inout_location_country_name,

wh.warehouse_search_key as inout_warehouse_search_key,
wh.warehouse_name as inout_warehouse_name,
wh.warehouse_description as inout_warehouse_description,
wh.warehouse_active as inout_warehouse_active,
wh.warehouse_in_transit as inout_warehouse_in_transit,
wh.warehouse_prevent_negative_inventory as inout_warehouse_prevent_negative_inventory,
wh.warehouse_loc_address1 as inout_warehouse_loc_address1,
wh.warehouse_loc_address2 as inout_warehouse_loc_address2,
wh.warehouse_loc_address3 as inout_warehouse_loc_address3,
wh.warehouse_loc_address4 as inout_warehouse_loc_address4,
wh.warehouse_loc_city as inout_warehouse_loc_city,
wh.warehouse_loc_state as inout_warehouse_loc_state,
wh.warehouse_loc_country_code as inout_warehouse_loc_country_code,
wh.warehouse_loc_country_name as inout_warehouse_loc_country_name,

ord.order_document_number,
ord.order_total_grand_raw,
ord.order_total_grand_all,
ord.order_total_lines_raw,
ord.order_total_lines_all,
ord.order_date_ordered,
inv.Invoice_document_number,
inv.invoice_total_grand_raw,
inv.invoice_total_grand_adj,
inv.invoice_total_grand_all,
inv.invoice_total_lines_raw,
inv.invoice_total_lines_adj,
inv.invoice_total_lines_all,
inv.Invoice_Sales_Transaction,
inv.Invoice_document_status,
inv.invoice_date,

activity.activity_search_key as inout_activity_search_key,
activity.activity_name as inout_activity_name,
activity.activity_search_key_name as inout_activity_search_key_name,
activity.activity_description as inout_activity_description,
activity.activity_summary as inout_activity_summary,
activity.activity_help as inout_activity_help,
activity.activity_id as inout_activity_id,

campaign.campaign_search_key as inout_campaign_search_key,
campaign.campaign_name as inout_campaign_name,
campaign.campaign_search_key_name as inout_campaign_search_key_name,
campaign.campaign_description as inout_campaign_description,
campaign.campaign_startdate as inout_campaign_startdate,
campaign.campaign_enddate as inout_campaign_enddate,
campaign.campaign_costs as inout_campaign_costs,
campaign.campaign_summary as inout_campaign_summary,
campaign.campaign_channel_name as inout_campaign_channel_name,
campaign.campaign_channel_description as inout_campaign_channel_description,
campaign.campaign_id as inout_campaign_id

FROM m_inout io
JOIN bi_bpartner_cache bp ON io.c_bpartner_id = bp.bpartner_id
LEFT JOIN bi_partner_location_cache bpl ON io.c_bpartner_location_id = bpl.partner_location_id
JOIN bi_client_cache c ON io.ad_client_id = c.client_id
JOIN bi_org_cache o ON io.ad_org_id = o.org_id
JOIN c_doctype dt ON io.c_doctype_id = dt.c_doctype_id
LEFT JOIN bi_order_cache ord ON io.c_order_id = ord.order_id
LEFT JOIN bi_invoice_cache inv ON io.c_invoice_id = inv.invoice_id
LEFT JOIN bi_warehouse_cache wh on io.m_warehouse_id = wh.warehouse_id
left join bi_activity_cache activity on io.c_activity_id = activity.activity_id
left join bi_campaign_cache campaign on io.c_campaign_id = campaign.campaign_id
;
SELECT 'inout.'||column_name||',' as inout FROM information_schema.columns WHERE  table_name   = 'bi_inout';
--SELECT COUNT(*) as inout_count FROM bi_inout;
CREATE MATERIALIZED VIEW bi_inout_cache AS select * from bi_inout;
create unique index bi_inout_cache_uidx on bi_inout_cache (inout_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_inout_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_inout_line AS 
--{{{
SELECT
c.*,
o.org_name,
o.org_search_key,

inout.InOut_Sales_Transaction,
inout.InOut_document_number,
inout.InOut_document_action,
inout.InOut_document_status,
inout.InOut_doctype_name,
inout.InOut_description,
inout.InOut_date_ordered,
inout.InOut_movement_date,
inout.inout_bpartner_search_key,
inout.inout_bpartner_name,
inout.inout_bpartner_name2,
inout.inout_bpartner_created,
inout.inout_bpartner_customer,
inout.inout_bpartner_vendor,
inout.inout_bpartner_employee,
inout.inout_bpartner_group_search_key,
inout.inout_bpartner_group_name,
inout.inout_bpartner_group_description,
inout.inout_location_name,
inout.inout_location_address1,
inout.inout_location_address2,
inout.inout_location_address3,
inout.inout_location_address4,
inout.inout_location_city,
inout.inout_location_state,
inout.inout_location_country_code,
inout.inout_location_country_name,

ol.order_line_lineno,
ol.order_line_qty_ordered,
ol.order_line_qty_invoiced,
ol.order_line_description,
ol.order_line_total_raw,
ol.order_line_total_all,

iol.m_inoutline_id as inout_line_id,
iol.line as inout_line_lineno,
iol.description as inout_line_description,
iol.movementqty as inout_line_movement_qty,
iol.created as inout_line_created,
iol.updated as inout_line_updated,

p.product_search_key as inout_line_product_search_key,
p.product_name as inout_line_product_name,
p.product_description as inout_line_product_description,
p.product_document_note as inout_line_product_document_note,
p.product_active as inout_line_product_active,
p.product_category_name as inout_line_product_category_name,

uom.uom_name as inout_line_uom_name, 
uom.uom_search_key as inout_line_uom_search_key, 

chg.charge_name as inout_line_charge_name,
chg.charge_description as inout_line_charge_description,

locator.warehouse_search_key as inout_line_warehouse_search_key,
locator.warehouse_name as inout_line_warehouse_name,
locator.warehouse_description as inout_line_warehouse_description,
locator.warehouse_active as inout_line_warehouse_active,
locator.warehouse_in_transit as inout_line_warehouse_in_transit,
locator.warehouse_prevent_negative_inventory as inout_line_warehouse_prevent_negative_inventory,
locator.warehouse_loc_address1 as inout_line_warehouse_loc_address1,
locator.warehouse_loc_address2 as inout_line_warehouse_loc_address2,
locator.warehouse_loc_address3 as inout_line_warehouse_loc_address3,
locator.warehouse_loc_address4 as inout_line_warehouse_loc_address4,
locator.warehouse_loc_city as inout_line_warehouse_loc_city,
locator.warehouse_loc_state as inout_line_warehouse_loc_state,
locator.warehouse_loc_country_code as inout_line_warehouse_loc_country_code,
locator.warehouse_loc_country_name as inout_line_warehouse_loc_country_name,
locator.locator_search_key as inout_line_locator_search_key,
locator.locator_x as inout_line_locator_x,
locator.locator_y as inout_line_locator_y,
locator.locator_z as inout_line_locator_z,
locator.locator_type as inout_line_locator_type,

activity.activity_search_key as inout_line_activity_search_key,
activity.activity_name as inout_line_activity_name,
activity.activity_search_key_name as inout_line_activity_search_key_name,
activity.activity_description as inout_line_activity_description,
activity.activity_summary as inout_line_activity_summary,
activity.activity_help as inout_line_activity_help,

campaign.campaign_search_key as inout_line_campaign_search_key,
campaign.campaign_name as inout_line_campaign_name,
campaign.campaign_search_key_name as inout_line_campaign_search_key_name,
campaign.campaign_description as inout_line_campaign_description,
campaign.campaign_startdate as inout_line_campaign_startdate,
campaign.campaign_enddate as inout_line_campaign_enddate,
campaign.campaign_costs as inout_line_campaign_costs,
campaign.campaign_summary as inout_line_campaign_summary,
campaign.campaign_channel_name as inout_line_campaign_channel_name,
campaign.campaign_channel_description as inout_line_campaign_channel_description

FROM m_inoutline iol
JOIN bi_inout_cache inout ON iol.m_inout_id = inout.inout_id
LEFT JOIN bi_charge_cache chg ON iol.c_charge_id=chg.charge_id
LEFT JOIN bi_order_line_cache ol ON iol.c_orderline_id = ol.order_line_id
LEFT JOIN bi_product_cache p ON iol.m_product_id = p.product_id
LEFT JOIN bi_uom_cache uom ON iol.c_uom_id = uom.uom_id
JOIN bi_client_cache c ON iol.ad_client_id = c.client_id
JOIN bi_org_cache o ON iol.ad_org_id = o.org_id
LEFT JOIN bi_locator_cache locator on iol.m_locator_id = locator.locator_id
left join bi_activity_cache activity on coalesce(iol.c_activity_id,inout.inout_activity_id) = activity.activity_id
left join bi_campaign_cache campaign on coalesce(iol.c_campaign_id,inout.inout_campaign_id) = campaign.campaign_id
;
SELECT 'inoutline.'||column_name||',' as inoutline FROM information_schema.columns WHERE  table_name   = 'bi_inout_line';
--SELECT COUNT(*) as inout_line_count FROM bi_inout_line;
CREATE MATERIALIZED VIEW bi_inout_line_cache AS  select * from bi_inout_line;
create unique index bi_inout_line_cache_uidx on bi_inout_line_cache (inout_line_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_inout_line_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_bank AS
--{{{
SELECT
c.*,
bank.c_bank_id as bank_id,
bank.name as bank_name,
bank.description as bank_description,
bank.created as bank_created,
bank.updated as bank_updated,
bank.isactive as bank_active
FROM c_bank bank
JOIN bi_client_cache c on bank.ad_client_id = c.client_id
;
SELECT 'bank.'||column_name||',' as bank FROM information_schema.columns WHERE  table_name   = 'bi_bank';
--SELECT COUNT(*) as bank_count FROM bi_bank;
CREATE MATERIALIZED VIEW bi_bank_cache AS select * from bi_bank;
create unique index bi_bank_cache_uidx on bi_bank_cache (bank_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_bank_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_bank_account AS
--{{{
SELECT
c.*,
bankacct.c_bankaccount_id as bank_account_id,
bank.bank_name,
bank.bank_description,
bank.bank_active,
bankacct.value as bank_account_search_key,
bankacct.name as bank_account_name,
bankacct.accountno as bank_account_number,
bankacct.description as bank_account_description,
bankacct.isactive as bank_account_active,
bankacct.isdefault as bank_account_default,
bankacct.creditlimit as bank_account_credit_limit,
bankacct.currentbalance as bank_account_current_balance,
bankacct.created as bank_account_created,
bankacct.updated as bank_account_updated,
curr.currency_iso_code as bank_account_currency_iso_code,
curr.currency_symbol as bank_account_currency_symbol,
curr.currency_description as bank_account_currency_description

FROM C_BankAccount bankacct 
JOIN bi_client_cache c on bankacct.ad_client_id = c.client_id
JOIN bi_bank_cache bank on bankacct.c_bank_id = bank.bank_id
JOIN bi_currency_cache curr on bankacct.c_currency_id = curr.currency_id
;
SELECT 'bankacct.'||column_name||',' as bank_account FROM information_schema.columns WHERE  table_name   = 'bi_bank_account';
--SELECT COUNT(*) as bank_account_count FROM bi_bank_account;
CREATE MATERIALIZED VIEW bi_bank_account_cache AS select * from bi_bank_account;
create unique index bi_bank_account_cache_uidx on bi_bank_account_cache (bank_account_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_bank_account_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_payment AS
--{{{
SELECT
c.*,
o.*,
pay.c_payment_id as payment_id,
pay.documentno as payment_document_number,
dt.name as payment_document_type,
pay.isreceipt as payment_receipt,
pay.datetrx as payment_date,
pay.dateacct as payment_date_account,
pay.description as payment_description,
pay.isprepayment as payment_prepay,
pay.payamt as payment_total_raw,
doctypemultiplier_birp(dt.c_doctype_id)*pay.payamt as payment_total_all,
tendertype.name as payment_tender_type,
pay.docstatus as payment_document_status,
pay.created as payment_created,
pay.updated as payment_updated,

bankacct.bank_account_search_key as payment_bank_account_search_key,
bankacct.bank_account_name as payment_bank_account_name,
bankacct.bank_account_number as payment_bank_account_number,
bankacct.bank_account_description as payment_bank_account_description,
bankacct.bank_account_currency_iso_code as payment_bank_account_currency_iso_code,
bankacct.bank_account_currency_symbol as payment_bank_account_currency_symbol,
bankacct.bank_account_currency_description as payment_bank_account_currency_description,

bp.bpartner_search_key as payment_bpartner_search_key,
bp.bpartner_name as payment_bpartner_name,
bp.bpartner_name2 as payment_bpartner_name2,
bp.bpartner_created as payment_bpartner_created,
bp.bpartner_updated as payment_bpartner_updated,
bp.bpartner_customer as payment_bpartner_customer,
bp.bpartner_vendor as payment_bpartner_vendor,
bp.bpartner_employee as payment_bpartner_employee,
bp.bpartner_group_search_key as payment_bpartner_group_search_key,
bp.bpartner_group_name as payment_bpartner_group_name,
bp.bpartner_group_description as payment_bpartner_group_description,

chg.charge_id as payment_charge_id,
chg.charge_name as payment_charge_name,
chg.charge_description as payment_charge_description,

curr.currency_iso_code as payment_currency_iso_code,
curr.currency_symbol as payment_currency_symbol,
curr.currency_description as payment_currency_description,

activity.activity_search_key as payment_activity_search_key,
activity.activity_name as payment_activity_name,
activity.activity_search_key_name as payment_activity_search_key_name,
activity.activity_description as payment_activity_description,
activity.activity_summary as payment_activity_summary,
activity.activity_help as payment_activity_help,

campaign.campaign_search_key as payment_campaign_search_key,
campaign.campaign_name as payment_campaign_name,
campaign.campaign_search_key_name as payment_campaign_search_key_name,
campaign.campaign_description as payment_campaign_description,
campaign.campaign_startdate as payment_campaign_startdate,
campaign.campaign_enddate as payment_campaign_enddate,
campaign.campaign_costs as payment_campaign_costs,
campaign.campaign_summary as payment_campaign_summary,
campaign.campaign_channel_name as payment_campaign_channel_name,
campaign.campaign_channel_description as payment_campaign_channel_description

FROM c_payment pay
JOIN bi_client_cache c on pay.ad_client_id = c.client_id
JOIN bi_org_cache o on pay.ad_org_id = o.org_id
LEFT JOIN bi_bank_account_cache bankacct on pay.c_bankaccount_id = bankacct.bank_account_id
LEFT JOIN c_doctype dt on pay.c_doctype_id = dt.c_doctype_id
LEFT JOIN bi_bpartner_cache bp on pay.c_bpartner_id = bp.bpartner_id
LEFT JOIN bi_charge_cache chg on pay.c_charge_id = chg.charge_id
LEFT JOIN AD_Ref_List tendertype on pay.tendertype = tendertype.value and AD_Reference_ID=214
LEFT JOIN bi_currency_cache curr on pay.c_currency_id = curr.currency_id
left join bi_activity_cache activity on pay.c_activity_id = activity.activity_id
left join bi_campaign_cache campaign on pay.c_campaign_id = campaign.campaign_id
;
SELECT 'pay.'||column_name||',' as payment FROM information_schema.columns WHERE  table_name   = 'bi_payment';
--SELECT COUNT(*) as payment FROM bi_payment;
CREATE MATERIALIZED VIEW bi_payment_cache AS select * from bi_payment;
create unique index bi_payment_cache_uidx on bi_payment_cache (payment_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_payment_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_requisition AS
--{{{
SELECT
c.*,
o.*,
reqn.m_requisition_id as requisition_id,
reqn.documentno AS requisition_document_number,
reqn.description AS requisition_description,
reqn.totallines AS requisition_total_lines,
reqn.daterequired AS requisition_date_required,
reqn.datedoc AS requisition_date_doc,
reqn.docstatus AS requisition_document_status,
reqn.created as requisition_created,
reqn.updated as requisition_updated,
dt.name as requisition_document_type,

wh.warehouse_search_key as requisition_warehouse_search_key,
wh.warehouse_name as requisition_warehouse_name,
wh.warehouse_description as requisition_warehouse_description,
wh.warehouse_active as requisition_warehouse_active,
wh.warehouse_in_transit as requisition_warehouse_in_transit,
wh.warehouse_prevent_negative_inventory as requisition_warehouse_prevent_negative_inventory,
wh.warehouse_loc_address1 as requisition_warehouse_loc_address1,
wh.warehouse_loc_address2 as requisition_warehouse_loc_address2,
wh.warehouse_loc_address3 as requisition_warehouse_loc_address3,
wh.warehouse_loc_address4 as requisition_warehouse_loc_address4,
wh.warehouse_loc_city as requisition_warehouse_loc_city,
wh.warehouse_loc_state as requisition_warehouse_loc_state,
wh.warehouse_loc_country_code as requisition_warehouse_loc_country_code,
wh.warehouse_loc_country_name as requisition_warehouse_loc_country_name,

u.user_search_key as requisition_user_search_key,
u.user_name as requisition_user_name,
u.user_description as requisition_user_description,
u.user_email as requisition_user_email,
u.user_phone as requisition_user_phone,
u.bpartner_search_key as requisition_bpartner_search_key,
u.bpartner_name as requisition_bpartner_name,
u.bpartner_name2 as requisition_bpartner_name2,
u.bpartner_created as requisition_bpartner_created,
u.bpartner_updated as requisition_bpartner_updated,
u.bpartner_customer as requisition_bpartner_customer,
u.bpartner_vendor as requisition_bpartner_vendor,
u.bpartner_employee as requisition_bpartner_employee,
u.bpartner_group_search_key as requisition_bpartner_group_search_key,
u.bpartner_group_name as requisition_bpartner_group_name,
u.bpartner_group_description as requisition_bpartner_group_description,
u.user_location_name as requisition_user_location_name,
u.user_location_created as requisition_user_location_created,
u.user_location_updated as requisition_user_location_updated,
u.user_location_address1 as requisition_user_location_address1,
u.user_location_address2 as requisition_user_location_address2,
u.user_location_address3 as requisition_user_location_address3,
u.user_location_address4 as requisition_user_location_address4,
u.user_location_city as requisition_user_location_city,
u.user_location_state as requisition_user_location_state,
u.user_location_country_code as requisition_user_location_country_code,
u.user_location_country_name as requisition_user_location_country_name,

pl.price_list_name as requisition_price_list_name,
pl.price_list_description as requisition_price_list_description,
pl.price_list_active as requisition_price_list_active,
pl.price_list_default as requisition_price_list_default,
pl.price_list_precision as requisition_price_list_precision,
pl.price_list_sales as requisition_price_list_sales,
pl.price_list_tax_included as requisition_price_list_tax_included,
pl.price_list_currency_iso_code as requisition_price_list_currency_iso_code,
pl.price_list_currency_symbol as requisition_price_list_currency_symbol,
pl.price_list_currency_description as requisition_price_list_currency_description

-- needs price list

FROM m_requisition reqn
JOIN bi_client_cache c ON reqn.ad_client_id = c.client_id
JOIN bi_org_cache o ON reqn.ad_org_id = o.org_id
JOIN c_doctype dt ON reqn.c_doctype_id = dt.c_doctype_id
JOIN bi_warehouse_cache wh on reqn.m_warehouse_id = wh.warehouse_id
JOIN bi_user_cache u on reqn.ad_user_id = u.user_id
LEFT JOIN bi_price_list_cache pl on reqn.m_pricelist_id = pl.price_list_id
;
SELECT 'requisition.'||column_name||',' as requisition FROM information_schema.columns WHERE  table_name   = 'bi_requisition';
--SELECT COUNT(*) as requisition_count FROM bi_requisition;
CREATE MATERIALIZED VIEW bi_requisition_cache AS select * from bi_requisition;
create unique index bi_requisition_cache_uidx on bi_requisition_cache (requisition_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_requisition_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_requisition_line AS
--{{{
SELECT

rl.m_requisitionline_id as requisition_line_id,

requisition.requisition_document_number,
requisition.requisition_description,
requisition.requisition_total_lines,
requisition.requisition_date_required,
requisition.requisition_date_doc,
requisition.requisition_document_status,
requisition.requisition_created,
requisition.requisition_updated,
requisition.requisition_document_type,
requisition.requisition_warehouse_search_key,
requisition.requisition_warehouse_name,
requisition.requisition_warehouse_description,
requisition.requisition_warehouse_active,
requisition.requisition_warehouse_in_transit,
requisition.requisition_warehouse_prevent_negative_inventory,
requisition.requisition_warehouse_loc_address1,
requisition.requisition_warehouse_loc_address2,
requisition.requisition_warehouse_loc_address3,
requisition.requisition_warehouse_loc_address4,
requisition.requisition_warehouse_loc_city,
requisition.requisition_warehouse_loc_state,
requisition.requisition_warehouse_loc_country_code,
requisition.requisition_warehouse_loc_country_name,
requisition.requisition_user_search_key,
requisition.requisition_user_name,
requisition.requisition_user_description,
requisition.requisition_user_email,
requisition.requisition_user_phone,
requisition.requisition_bpartner_search_key,
requisition.requisition_bpartner_name,
requisition.requisition_bpartner_name2,
requisition.requisition_bpartner_created,
requisition.requisition_bpartner_updated,
requisition.requisition_bpartner_customer,
requisition.requisition_bpartner_vendor,
requisition.requisition_bpartner_employee,
requisition.requisition_bpartner_group_search_key,
requisition.requisition_bpartner_group_name,
requisition.requisition_bpartner_group_description,
requisition.requisition_price_list_name,
requisition.requisition_price_list_description,
requisition.requisition_price_list_active,
requisition.requisition_price_list_default,
requisition.requisition_price_list_precision,
requisition.requisition_price_list_sales,
requisition.requisition_price_list_tax_included,
requisition.requisition_price_list_currency_iso_code,
requisition.requisition_price_list_currency_symbol,
requisition.requisition_price_list_currency_description,

rl.line as requisition_line_lineno,
rl.description as requisition_line_description,
rl.qty as requisition_line_qty, 
rl.priceactual as requisition_line_price,
rl.linenetamt as requisition_line_linenetamt, 
rl.created as requisition_line_created,
rl.updated as requisition_line_updated,

p.product_search_key as requisition_line_product_search_key,
p.product_name as requisition_line_product_name,
p.product_description as requisition_line_product_description,
p.product_document_note as requisition_line_product_document_note,
p.product_category_name as requisition_line_product_category_name,

uom.uom_name as requisition_line_uom_name,
uom.uom_search_key as requisition_line_uom_search_key,

orderline.order_document_number,
orderline.order_total_grand_raw,
orderline.order_total_grand_all,
orderline.order_total_lines_raw,
orderline.order_total_lines_all,
orderline.order_document_status,
orderline.order_created,
orderline.order_updated,
orderline.order_ship_bpartner_search_key,
orderline.order_ship_bpartner_name,
orderline.order_ship_bpartner_name2,
orderline.order_ship_bpartner_created,
orderline.order_ship_bpartner_updated,
orderline.order_ship_bpartner_customer,
orderline.order_ship_bpartner_vendor,
orderline.order_ship_bpartner_employee,
orderline.order_ship_bpartner_group_search_key,
orderline.order_ship_bpartner_group_name,
orderline.order_ship_bpartner_group_description,
orderline.order_ship_location_name,
orderline.order_ship_location_address1,
orderline.order_ship_location_address2,
orderline.order_ship_location_address3,
orderline.order_ship_location_address4,
orderline.order_ship_location_city,
orderline.order_ship_location_state,
orderline.order_ship_location_country_code,
orderline.order_ship_location_country_name,
orderline.order_line_lineno,
orderline.order_line_qty_ordered,
orderline.order_line_qty_entered,
orderline.order_line_qty_invoiced,
orderline.order_line_qty_delivered,
orderline.order_line_description,
orderline.order_line_price_entered,
orderline.order_line_total_raw,
orderline.order_line_total_all,
orderline.order_line_created,
orderline.order_line_updated,

bp.bpartner_search_key as requisition_line_bpartner_search_key,
bp.bpartner_name as requisition_line_bpartner_name,
bp.bpartner_name2 as requisition_line_bpartner_name2,
bp.bpartner_created as requisition_line_bpartner_created,
bp.bpartner_customer as requisition_line_bpartner_customer,
bp.bpartner_vendor as requisition_line_bpartner_vendor,
bp.bpartner_employee as requisition_line_bpartner_employee,
bp.bpartner_group_search_key as requisition_line_bpartner_group_search_key,
bp.bpartner_group_name as requisition_line_bpartner_group_name,
bp.bpartner_group_description as requisition_line_bpartner_group_description

FROM m_requisitionline rl
JOIN bi_requisition_cache requisition ON rl.m_requisition_id = requisition.requisition_id
LEFT JOIN bi_order_line_cache orderline ON rl.c_orderline_id = orderline.order_line_id
LEFT JOIN bi_product_cache p ON rl.m_product_id = p.product_id
LEFT JOIN bi_uom_cache uom ON rl.c_uom_id = uom.uom_id
LEFT JOIN bi_bpartner_cache bp ON rl.c_bpartner_id=bp.bpartner_id
;
SELECT 'requisitionline.'||column_name||',' as requisitionline FROM information_schema.columns WHERE  table_name   = 'bi_requisition_line';
--SELECT COUNT(*) as requisition_line_count FROM bi_requisition_line;
CREATE MATERIALIZED VIEW bi_requisition_line_cache AS select * from bi_requisition_line;
create unique index bi_requisition_line_cache_uidx on bi_requisition_line_cache (requisition_line_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_requisition_line_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_request AS
--{{{
SELECT 
c.*,
o.*,
req.r_request_id as request_id,
req.documentno as request_document_number,
reqtype.name AS request_type,
reqcat.name AS request_category,

reqstat.name AS request_status,
reqstat.isopen as request_status_open,
reqstat.isclosed as request_status_close,
reqstat.isfinalclose as request_status_final_close,

resol.name AS request_resolution,
req.priority as request_priority,
req.summary as request_summary,
req.datelastaction as request_date_last_action,
req.datenextaction as request_date_next_action,
req.lastresult as request_lastresult,
req.startdate as request_startdate,
req.closedate as request_closedate,
req.created as request_created,
req.updated as request_updated,

sr.name as request_user,
role.name as request_role,
bp.name as bpartner_name,
bp.value as bpartner_search_key,
ord.documentno as order_document_number,
p.value as product_search_key,
p.name as product_name,
proj.name as project_name,
proj.value as project_search_key,
inv.documentno as invoice_document_number,
pay.documentno as payment_document_number


FROM r_request req
JOIN r_requesttype reqtype ON req.r_requesttype_id = reqtype.r_requesttype_id
LEFT JOIN r_category reqcat ON req.r_category_id=reqcat.r_category_id
LEFT JOIN r_status reqstat ON req.r_status_id=reqstat.r_status_id
LEFT JOIN r_resolution resol ON req.r_resolution_id=resol.r_resolution_id
LEFT JOIN c_bpartner bp ON req.c_bpartner_id = bp.c_bpartner_id
JOIN bi_client_cache c ON req.ad_client_id = c.client_id
JOIN bi_org_cache o ON req.ad_org_id = o.org_id
LEFT JOIN c_order ord ON req.c_order_id=ord.c_order_id
LEFT JOIN m_product p ON req.m_product_id=p.m_product_id
LEFT JOIN ad_user sr on req.salesrep_id = sr.ad_user_id
LEFT JOIN ad_role role on req.ad_role_id = role.ad_role_id
LEFT JOIN c_project proj on req.c_project_id = proj.c_project_id
LEFT JOIN c_invoice inv on req.c_invoice_id = inv.c_invoice_id
LEFT JOIN c_payment pay on req.c_payment_id = pay.c_payment_id
;
SELECT 'request.'||column_name||',' as request FROM information_schema.columns WHERE  table_name   = 'bi_request';
--SELECT COUNT(*) as request_count FROM bi_request;
CREATE MATERIALIZED VIEW bi_request_cache AS select * from bi_request;
create unique index bi_request_cache_uidx on bi_request_cache (request_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_request_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_production as 
--{{{
SELECT
c.*,
o.*,
production.m_production_id as production_id,
production.documentno as production_document_number,
production.name as production_name,
production.description as production_description,
production.datepromised as production_date_promised,
production.movementdate as production_movement_date,
production.iscreated as production_records_created,
production.docstatus as production_document_status,
production.created as production_created,
production.updated as production_updated,

orderline.order_document_number,
orderline.order_total_grand_raw,
orderline.order_total_grand_all,
orderline.order_total_lines_raw,
orderline.order_total_lines_all,
orderline.order_sales_transaction,
orderline.order_document_status,
orderline.order_date_ordered,
orderline.order_document_type,
orderline.order_line_lineno,
orderline.order_line_qty_ordered,
orderline.order_line_qty_entered,
orderline.order_line_qty_invoiced,
orderline.order_line_qty_delivered,
orderline.order_line_description,
orderline.order_line_price_entered,
orderline.order_line_total_raw,
orderline.order_line_total_all,

prod.product_search_key as production_product_search_key,
prod.product_name as production_product_name,
prod.product_description as production_product_description,
prod.product_document_note as production_product_document_note,
prod.product_active as production_product_active,
prod.product_category_name as production_product_category_name,
prod.product_uom_name as production_product_uom_name,

bp.bpartner_search_key,
bp.bpartner_name,
bp.bpartner_name2,
bp.bpartner_created,
bp.bpartner_customer,
bp.bpartner_vendor,
bp.bpartner_group_search_key,
bp.bpartner_group_name,
bp.bpartner_group_description

from M_Production production
left join bi_product_cache prod on production.m_product_id = prod.product_id
join bi_client_cache c on production.ad_client_id = c.client_id
join bi_org_cache o on production.ad_org_id = o.org_id
left join bi_order_line_cache orderline on production.c_orderline_id = orderline.order_line_id
left join bi_bpartner_cache bp on production.c_bpartner_id = bp.bpartner_id
;
SELECT 'production.'||column_name||',' as production FROM information_schema.columns WHERE  table_name   = 'bi_production';
--SELECT COUNT(*) as production_count FROM bi_production;
CREATE MATERIALIZED VIEW bi_production_cache as  select * from bi_production;
create unique index bi_production_cache_uidx on bi_production_cache (production_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_production_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_production_line as
--{{{
select 

production.production_document_number,
production.production_name,
production.production_description,
production.production_date_promised,
production.production_movement_date,
production.production_records_created,
production.production_document_status,
production.production_created,
production.production_updated,
production.order_document_number,
production.order_total_grand_raw,
production.order_total_grand_all,
production.order_total_lines_raw,
production.order_total_lines_all,
production.order_sales_transaction,
production.order_document_status,
production.order_date_ordered,
production.order_document_type,
production.order_line_lineno,
production.order_line_qty_ordered,
production.order_line_qty_entered,
production.order_line_qty_invoiced,
production.order_line_qty_delivered,
production.order_line_description,
production.order_line_price_entered,
production.order_line_total_raw,
production.order_line_total_all,
production.production_product_search_key,
production.production_product_name,
production.production_product_description,
production.production_product_document_note,
production.production_product_active,
production.production_product_category_name,
production.production_product_uom_name,
production.bpartner_search_key,
production.bpartner_name,
production.bpartner_name2,
production.bpartner_created,
production.bpartner_customer,
production.bpartner_vendor,

productionline.m_productionline_id as production_line_id,
productionline.line as produciton_line_lineno,
productionline.isendproduct as production_line_end_product,
productionline.isactive as production_line_active,
productionline.plannedqty as production_line_qty_planned,
productionline.qtyused as production_line_qty_used,
productionline.description as production_line_description,
productionline.created as production_line_created,
productionline.updated as production_line_updated,

locator.warehouse_search_key,
locator.warehouse_name,
locator.warehouse_description,
locator.warehouse_active,
locator.warehouse_in_transit,
locator.warehouse_prevent_negative_inventory,
locator.warehouse_loc_address1,
locator.warehouse_loc_address2,
locator.warehouse_loc_address3,
locator.warehouse_loc_address4,
locator.warehouse_loc_city,
locator.warehouse_loc_state,
locator.warehouse_loc_country_code,
locator.warehouse_loc_country_name,
locator.locator_id,
locator.locator_search_key,
locator.locator_x,
locator.locator_y,
locator.locator_z,
locator.locator_type,

prod.product_search_key as production_line_product_search_key,
prod.product_name as production_line_product_name,
prod.product_description as production_line_product_description,
prod.product_document_note as production_line_product_document_note,
prod.product_active as production_line_product_active,
prod.product_category_name as production_line_product_category_name,
prod.product_uom_name as production_line_product_uom_name

FROM m_productionline productionline
JOIN bi_production_cache production on productionline.m_production_id = production.production_id
LEFT JOIN bi_product_cache prod on productionline.m_product_id = prod.product_id
LEFT JOIN bi_locator_cache locator on productionline.m_locator_id = locator.locator_id
;
SELECT 'productionline.'||column_name||',' as productionline FROM information_schema.columns WHERE  table_name   = 'bi_production_line';
--SELECT COUNT(*) as production_line_count FROM bi_production_line;
CREATE MATERIALIZED VIEW bi_production_line_cache as select * from bi_production_line;
create unique index bi_production_line_cache_uidx on bi_production_line_cache (production_line_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_production_line_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_project_issue AS
--{{{
SELECT
c.*,

projissue.c_projectissue_id as project_issue_id,
projissue.isactive as project_issue_active,
projissue.line as project_issue_line_number,
projissue.movementdate as project_issue_date_movement,
projissue.movementqty as project_issue_quantity_movement,
projissue.description as project_issue_description,
projissue.processed as project_issue_processed,

proj.project_search_key as project_issue_project_search_key,
proj.project_name as project_issue_project_name,
proj.project_description as project_issue_project_description,
proj.project_active as project_issue_project_active,
proj.project_summary as project_issue_project_summary,
proj.project_note as project_issue_project_note,
proj.project_date_contract as project_issue_project_date_contract,
proj.project_date_finish as project_issue_project_date_finish,
proj.project_created as project_issue_project_created,
proj.project_updated as project_issue_project_updated,
proj.project_line_level as project_issue_project_line_level,
proj.project_bpartner_search_key as project_issue_project_bpartner_search_key,
proj.project_bpartner_name as project_issue_project_bpartner_name,
proj.project_bpartner_name2 as project_issue_project_bpartner_name2,
proj.project_bpartner_created as project_issue_project_bpartner_created,
proj.project_bpartner_updated as project_issue_project_bpartner_updated,
proj.project_bpartner_customer as project_issue_project_bpartner_customer,
proj.project_bpartner_vendor as project_issue_project_bpartner_vendor,
proj.project_bpartner_employee as project_issue_project_bpartner_employee,
proj.project_bpartner_group_search_key as project_issue_project_bpartner_group_search_key,
proj.project_bpartner_group_name as project_issue_project_bpartner_group_name,
proj.project_bpartner_group_description as project_issue_project_bpartner_group_description,

prod.product_search_key as project_issue_product_search_key,
prod.product_created as project_issue_product_created,
prod.product_updated as project_issue_product_updated,
prod.product_name as project_issue_product_name,
prod.product_description as project_issue_product_description,
prod.product_document_note as project_issue_product_document_note,
prod.product_active as project_issue_product_active,
prod.product_type as project_issue_product_type,
prod.product_category_name as project_issue_product_category_name,
prod.product_uom_name as project_issue_product_uom_name,

locator.warehouse_search_key as project_issue_warehouse_search_key,
locator.warehouse_name as project_issue_warehouse_name,
locator.warehouse_description as project_issue_warehouse_description,
locator.warehouse_active as project_issue_warehouse_active,
locator.warehouse_in_transit as project_issue_warehouse_in_transit,
locator.warehouse_prevent_negative_inventory as project_issue_warehouse_prevent_negative_inventory,
locator.warehouse_created as project_issue_warehouse_created,
locator.warehouse_updated as project_issue_warehouse_updated,
locator.warehouse_loc_address1 as project_issue_warehouse_loc_address1,
locator.warehouse_loc_address2 as project_issue_warehouse_loc_address2,
locator.warehouse_loc_address3 as project_issue_warehouse_loc_address3,
locator.warehouse_loc_address4 as project_issue_warehouse_loc_address4,
locator.warehouse_loc_city as project_issue_warehouse_loc_city,
locator.warehouse_loc_state as project_issue_warehouse_loc_state,
locator.warehouse_loc_country_code as project_issue_warehouse_loc_country_code,
locator.warehouse_loc_country_name as project_issue_warehouse_loc_country_name,
locator.locator_search_key as project_issue_locator_search_key,
locator.locator_x as project_issue_locator_x,
locator.locator_y as project_issue_locator_y,
locator.locator_z as project_issue_locator_z,
locator.locator_created as project_issue_locator_created,
locator.locator_updated as project_issue_locator_updated,
locator.locator_type as project_issue_locator_type,

inoutline.inout_document_number as project_issue_inout_document_number,
inoutline.inout_document_action as project_issue_inout_document_action,
inoutline.inout_document_status as project_issue_inout_document_status,
inoutline.inout_doctype_name as project_issue_inout_doctype_name,
inoutline.inout_description as project_issue_inout_description,
inoutline.inout_date_ordered as project_issue_inout_date_ordered,
inoutline.inout_movement_date as project_issue_inout_movement_date,
inoutline.order_line_lineno as project_issue_order_line_lineno,
inoutline.order_line_qty_ordered as project_issue_order_line_qty_ordered,
inoutline.order_line_qty_invoiced as project_issue_order_line_qty_invoiced,
inoutline.order_line_description as project_issue_order_line_description,
inoutline.order_line_total_raw as project_issue_order_line_total_raw,
inoutline.order_line_total_all as project_issue_order_line_total_all,
inoutline.inout_line_id as project_issue_inout_line_id,
inoutline.inout_line_lineno as project_issue_inout_line_lineno,
inoutline.inout_line_description as project_issue_inout_line_description,
inoutline.inout_line_movement_qty as project_issue_inout_line_movement_qty,
inoutline.inout_line_created as project_issue_inout_line_created,
inoutline.inout_line_updated as project_issue_inout_line_updated

FROM c_projectissue projissue
JOIN bi_client_cache c on projissue.ad_client_id = c.client_id
JOIN bi_project_cache proj on projissue.c_project_id = proj.project_id
LEFT JOIN bi_product_cache prod on projissue.m_product_id = prod.product_id
LEFT JOIN bi_locator_cache locator on projissue.m_locator_id = locator.locator_id
LEFT JOIN bi_inout_line_cache inoutline on projissue.m_inoutline_id = inoutline.inout_line_id
;
SELECT 'projissue.'||column_name||',' as project_issue FROM information_schema.columns WHERE  table_name   = 'bi_project_issue';
--SELECT COUNT(*) as project_issue_count FROM bi_project_issue;
CREATE MATERIALIZED VIEW bi_project_issue_cache AS select * from bi_project_issue;
create unique index bi_project_issue_cache_uidx on bi_project_issue_cache (project_issue_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_project_issue_cache');
--add all materialized view indexes here...
--}}}

CREATE VIEW bi_project_line AS
--{{{
SELECT
projline.c_projectline_id as project_line_id,
proj.*,
projph.project_phase_sequence_number,
projph.project_phase_name,
projph.project_phase_description,
projph.project_phase_active,
projph.project_phase_complete,
projph.project_phase_date_start,
projph.project_phase_date_end,
projph.project_phase_invoice_rule,
projph.project_phase_total_planned,
projph.project_phase_quantity,

projline.line as project_line_number,
projline.isactive as project_line_active,
projline.description as project_line_description,
projline.plannedprice as project_line_price_planned,
projline.plannedqty as project_line_quantity_planned,
projline.plannedamt as project_line_total_planned,
projline.committedamt as project_line_total_committed,
projline.committedqty as project_line_quantity_committed,
projline.invoicedamt as project_line_total_invoiced,
projline.invoicedqty as project_line_quantity_invoiced,
projline.processed as project_line_processed,

prod.product_search_key as project_line_product_search_key,
prod.product_created as project_line_product_created,
prod.product_updated as project_line_product_updated,
prod.product_name as project_line_product_name,
prod.product_description as project_line_product_description,
prod.product_document_note as project_line_product_document_note,
prod.product_active as project_line_product_active,
prod.product_type as project_line_product_type,
coalesce(prodcat.name,prod.product_category_name) as project_line_product_category_name,

sord.order_document_number as project_line_sales_order_document_number,
sord.order_document_type as project_line_sales_order_document_type,
sord.order_document_type_id as project_line_sales_order_document_type_id,
sord.order_order_reference as project_line_sales_order_order_reference,
sord.order_description as project_line_sales_order_description,
sord.order_date_promised as project_line_sales_order_date_promised,
sord.order_date_ordered as project_line_sales_order_date_ordered,
sord.order_delivery_rule as project_line_sales_order_delivery_rule,
sord.order_invoice_rule as project_line_sales_order_invoice_rule,
sord.order_priority as project_line_sales_order_priority,
sord.order_total_grand_raw as project_line_sales_order_total_grand_raw,
sord.order_total_grand_all as project_line_sales_order_total_grand_all,
sord.order_total_lines_raw as project_line_sales_order_total_lines_raw,
sord.order_total_lines_all as project_line_sales_order_total_lines_all,
sord.order_sales_transaction as project_line_sales_order_sales_transaction,
sord.order_document_status as project_line_sales_order_document_status,
sord.order_created as project_line_sales_order_created,
sord.order_updated as project_line_sales_order_updated,

pord.order_document_number as project_line_purchase_order_document_number,
pord.order_document_type as project_line_purchase_order_document_type,
pord.order_document_type_id as project_line_purchase_order_document_type_id,
pord.order_order_reference as project_line_purchase_order_order_reference,
pord.order_description as project_line_purchase_order_description,
pord.order_date_promised as project_line_purchase_order_date_promised,
pord.order_date_ordered as project_line_purchase_order_date_ordered,
pord.order_delivery_rule as project_line_purchase_order_delivery_rule,
pord.order_invoice_rule as project_line_purchase_order_invoice_rule,
pord.order_priority as project_line_purchase_order_priority,
pord.order_total_grand_raw as project_line_purchase_order_total_grand_raw,
pord.order_total_grand_all as project_line_purchase_order_total_grand_all,
pord.order_total_lines_raw as project_line_purchase_order_total_lines_raw,
pord.order_total_lines_all as project_line_purchase_order_total_lines_all,
pord.order_sales_transaction as project_line_purchase_order_sales_transaction,
pord.order_document_status as project_line_purchase_order_document_status,
pord.order_created as project_line_purchase_order_created,
pord.order_updated as project_line_purchase_order_updated,

production.production_document_number as project_line_production_document_number,
production.production_name as project_line_production_name,
production.production_description as project_line_production_description,
production.production_date_promised as project_line_production_date_promised,
production.production_movement_date as project_line_production_movement_date,
production.production_records_created as project_line_production_records_created,
production.production_document_status as project_line_production_document_status,
production.production_created as project_line_production_created,
production.production_updated as project_line_production_updated

--projectIssue

FROM c_projectline projline
JOIN bi_project_cache proj on projline.c_project_id = proj.project_id
LEFT JOIN bi_project_phase_cache projph on projline.c_projectphase_id = projph.project_phase_id
LEFT JOIN m_product_category prodcat on projline.m_product_category_id = prodcat.m_product_category_id
LEFT JOIN bi_product_cache prod on projline.m_product_id = prod.product_id
LEFT JOIN bi_order_cache sord on projline.c_order_id = sord.order_id
LEFT JOIN bi_order_cache pord on projline.c_orderpo_id = pord.order_id
LEFT JOIN bi_production_cache production on projline.m_production_id = production.production_id
;
SELECT 'projline.'||column_name||',' as project_line FROM information_schema.columns WHERE  table_name   = 'bi_project_line';
--SELECT COUNT(*) as project_line_count FROM bi_project_line;
CREATE MATERIALIZED VIEW bi_project_line_cache AS select * from bi_project_line;
create unique index bi_project_line_cache_uidx on bi_project_line_cache (project_line_id);
insert into adempiere.bi_mat_view_create_order (name) values ('bi_project_line_cache');
--add all materialized view indexes here...
--}}}

-- allow biaccess role to bi_% views
-- note this is not really needed since the materialized/cached views contain the high-speed data
-- note keeping just in case
--{{{
SELECT   CONCAT('GRANT SELECT ON adempiere.', TABLE_NAME, ' to biaccess;commit;')
FROM     INFORMATION_SCHEMA.TABLES
WHERE    TABLE_SCHEMA = 'adempiere'
    AND TABLE_NAME LIKE 'bi_%'
;

--dynamically create grant on materialized views
SELECT   CONCAT('GRANT SELECT ON adempiere.', relname, ' to biaccess;commit;')
FROM   pg_class
WHERE  relkind = 'm'
    AND relname LIKE 'bi_%'
;
--}}}

commit;
