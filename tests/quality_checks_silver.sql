/*
===============================================================================
Quality Checks
===============================================================================
Script Idea:
    This script for various quality checks for data consistency, accuracy, 
    and standardization in the 'silver' layer. It includes checks for:
    - Null or duplicates.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

When to use:
    - Run these scripts after load data in silver layer.
===============================================================================
*/


-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================
-- Check Null or duplicates in primary key 
-- Expectation: No results

SELECT cst_id, COUNT(*) FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted space
-- Expectation: No results

SELECT cst_firstname FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- Check for unwanted space
-- Expectation: No results

SELECT cst_lastname FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Data standartization and Consistency
-- Just 'Male' and 'Female' types + n/a (without NULL)
SELECT DISTINCT cst_gndr  FROM silver.crm_cust_info;

-- Data standartization and Consistency
-- Just 'Single' and 'Married' types + n/a (without NULL)
SELECT DISTINCT cst_marital_status   FROM silver.crm_cust_info;

-- ====================================================================
-- Checking 'silver.crm_prd_info'
-- ====================================================================

-- Check Null or duplicates in primary key 
-- Expectation: No results
SELECT prd_id, Count(*) FROM silver.crm_prd_info
GROUP BY prd_id
HAVING Count(*) > 1 or prd_id is NULL

-- Check for unwanted space
-- Expectation: No results

SELECT prd_nm FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

--Check for negative costs
-- Expectation: No negatives or NULLS 

SELECT prd_cost  FROM silver.crm_prd_info
WHERE prd_cost < 0 or prd_cost is NULL;

-- Data standartization and Consistency
SELECT DISTINCT prd_line  FROM silver.crm_prd_info;

--Check for invalid Date Orders
SELECT * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt 


-- ====================================================================
-- Checking 'silver.sales_details'
-- ====================================================================
-- Check for unwanted space
-- Expectation: No results
SELECT sls_ord_num  FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Check created columns in crm_prd_info
-- Expectation: No results
SELECT *  FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- Check integrity columns in crm_cust_info
-- Expectation: No results
SELECT *  FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);


-- Check for invalid sls_order_dt
-- Expectation: No results
SELECT 
    sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt < '1900-01-01'
   OR sls_order_dt > '2050-01-01';


-- Check for invalid sls_ship_dt
-- Expectation: No results
SELECT 
    sls_ship_dt
FROM silver.crm_sales_details
WHERE  sls_ship_dt < '1900-01-01'
   OR sls_ship_dt > '2050-01-01';


-- Check for invalid sls_due_dt
-- Expectation: No results
SELECT 
    sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt < '1900-01-01'
   OR sls_due_dt > '2050-01-01';


-- Check for invalidate dates
-- Expectation: No results
SELECT * FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check data consistency: between sales,price, quant.
--> Sales = quant * price
--> No negative values or zero/null
SELECT DISTINCT
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
END AS sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL 
OR sls_quantity IS NULL 
OR sls_price IS NULL
OR sls_sales <= 0 
OR sls_quantity <= 0 
OR sls_price <= 0 
ORDER BY sls_sales,sls_quantity,sls_price

-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================

-- Data standartization and Consistency
-- Just 'Male' and 'Female' types + n/a (without NULL)
SELECT DISTINCT gen  FROM silver.erp_cust_az12;

-- Out of range
-- Expectetion: no results
SELECT  bdate  FROM silver.erp_cust_az12
WHERE  bdate  > GETDATE()

-- Check if gen have tabulation 
-- If last_codepoint = 9/10/13/160, needs to update 
/*
 UPDATE bronze.erp_cust_az12
SET gen = REPLACE(REPLACE(gen, CHAR(13), ''), CHAR(10), '')
WHERE gen LIKE '%' + CHAR(13) + '%' OR gen LIKE '%' + CHAR(10) + '%';
*/
SELECT TOP 50
    QUOTENAME(gen)       AS raw_value,
    DATALENGTH(gen)      AS bytes,
    LEN(gen)             AS len_chars,
    UNICODE(LEFT(gen,1)) AS first_codepoint,
    UNICODE(RIGHT(gen,1))AS last_codepoint
FROM silver.erp_cust_az12
WHERE gen IS NOT NULL
GROUP BY gen, DATALENGTH(gen), LEN(gen);

-- ====================================================================
-- Checking 'silver.erp_loc_a101'
-- ====================================================================
-- Data standartization and Consistency
SELECT DISTINCT cntry as old_cntry,
CASE
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS 
from silver.erp_loc_a101
ORDER BY cntry;


-- ====================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ====================================================================
-- Unwanted spaces

select cat from silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) or subcat != TRIM(subcat) or maintenance != TRIM(maintenance);


-- Data Standartization
SELECT DISTINCT cat from silver.erp_px_cat_g1v2

-- Data Standartization
SELECT DISTINCT subcat from silver.erp_px_cat_g1v2

-- Data Standartization
SELECT DISTINCT maintenance  from silver.erp_px_cat_g1v2
