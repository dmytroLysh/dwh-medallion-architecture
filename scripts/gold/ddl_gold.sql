/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Idea:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)


Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

DROP VIEW IF EXISTS gold.dim_customers;

CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	la.cntry as country,
	ci.cst_marital_status as marital_status,
	CASE WHEN ci.cst_gndr != 'n\a' THEN ci.cst_gndr
	ELSE COALESCE(ca.gen, 'n\a')
	end as gender,
	ca.bdate as birth_date,
	ci.cst_create_date as create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca 
ON ci.cst_key = ca.cid 
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================

DROP VIEW IF EXISTS gold.dim_products

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER (ORDER BY cpi.prd_start_dt,cpi.prd_key) as product_key,
	cpi.prd_id as product_id,
	cpi.prd_key as product_number,
	cpi.prd_nm as product_name,
	cpi.cat_id as category_id,
	epcgv.cat as category,
	epcgv.subcat as subcategory,
	epcgv.maintenance,
	cpi.prd_cost as cost,
	cpi.prd_line as product_line,
	cpi.prd_start_dt as start_date
FROM silver.crm_prd_info cpi
LEFT JOIN silver.erp_px_cat_g1v2 epcgv 
ON cpi.cat_id  = epcgv.id 
WHERE cpi.prd_end_dt is NULL

-- =============================================================================
-- Create Dimension: gold.fact_sales
-- =============================================================================

DROP VIEW IF EXISTS gold.fact_sales

CREATE VIEW gold.fact_sales AS
SELECT 
	csd.sls_ord_num as order_number,
	dp.product_key,
	dc.customer_key,
	csd.sls_order_dt as order_date,
	csd.sls_ship_dt as shipping_date,
	csd.sls_due_dt as due_date,
	csd.sls_sales as sales_amount,
	csd.sls_quantity as quantity,
	csd.sls_price as price
FROM silver.crm_sales_details csd
LEFT JOIN gold.dim_products dp 
ON csd.sls_prd_key  = dp.product_number 
LEFT JOIN gold.dim_customers dc 
ON csd.sls_cust_id = dc.customer_id 


