	/*
	================================================================================================
	 Procedure : Load Silver Layer (Bronze -> Silver)
	================================================================================================
		This code procedure performs the ETL process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
	
	Usage Example: 
		EXEC silver.load_silver;
	
	================================================================================================ 
	 */

CREATE OR ALTER PROCEDURE silver.load_silver AS
	BEGIN
		DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
		BEGIN try
		  SET @batch_start_time = GETDATE();

PRINT('=================================================');
PRINT('Loading Silver Layer');
PRINT('=================================================');
PRINT('-------------------------------------------------');
PRINT('Loading CRM Tables');
PRINT('-------------------------------------------------');


PRINT('>>Truncating table: silver.crm_cust_info')
TRUNCATE TABLE silver.crm_cust_info;

PRINT('>>Inserting data into: silver.crm_cust_info')
INSERT INTO silver.crm_cust_info (cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_gndr,
cst_marital_status,
cst_create_date) 
SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname) as cst_lastname,
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	ELSE 'n\a'
END cst_gndr,
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	ELSE 'n\a'
END cst_marital_status,
cst_create_date
FROM 
(SELECT *,
ROW_NUMBER() OVER (PARTITION  BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL
) t1 WHERE flag_last = 1

PRINT('>>Truncating table: silver.crm_prd_info')
TRUNCATE TABLE silver.crm_prd_info;

PRINT('>>Inserting data into: silver.crm_prd_info')
INSERT INTO silver.crm_prd_info (
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt)

SELECT 
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-','_') as cat_id, -- Extract category_id
SUBSTRING(prd_key, 7, len(prd_key)) AS  prd_key, -- Extract product key
prd_nm,
ISNULL(prd_cost,0) as prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	ELSE 'n/a'
END AS prd_line, -- Descriptive values
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD (prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) as prd_end_dt -- Calculate end date based on the next start date minus 1 day
FROM bronze.crm_prd_info;

PRINT('>>Truncating table: silver.sales_details')
TRUNCATE TABLE silver.crm_sales_details;

PRINT('>>Inserting data into: silver.crm_sales_details')
INSERT INTO silver.crm_sales_details (
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0 or LEN(sls_order_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
END AS sls_order_dt,
CASE WHEN sls_ship_dt = 0 or LEN(sls_ship_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
END AS sls_ship_dt,
CASE WHEN sls_due_dt = 0 or LEN(sls_due_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;




PRINT('-------------------------------------------------');
PRINT('Loading ERP Tables');
PRINT('-------------------------------------------------');


SET @batch_end_time = GETDATE();
	PRINT '================================================='
	PRINT 'Loading silver layer is completed';
	PRINT '>> Total Load duration: ' + CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds';
	PRINT '================================================='
	END try
	BEGIN catch
	PRINT('=================================================');
	PRINT('ERROR LOADING Silver LAYER');
	PRINT 'Eror message:' + ERROR_MESSAGE();
	PRINT 'Eror number:' + CAST(ERROR_NUMBER() AS NVARCHAR);
	PRINT 'Eror state:' + CAST(ERROR_STATE() AS NVARCHAR);
	PRINT('=================================================');
	END catch
END
