	/*
	================================================================================================
	 Procedure : Load Bronze Layer (Source -> Bronze)
	================================================================================================
		This code loads data into the bronze schema from external csv files. 
			Actions: 
			- Truncate the tables before loading data.
			- Uses BULK INSERT command to load data from csv to bronze tables 
			- Add error handling and print time 
	
	Usage Example: 
		EXEC bronze.load_bronze;
	
	================================================================================================ 
	 */
	
	
	CREATE OR ALTER PROCEDURE bronze.load_bronze AS
	BEGIN
		DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
		BEGIN try
		  SET @batch_start_time = GETDATE();
	      PRINT('=================================================');
	      PRINT('Loading bronze layer')
	      PRINT('=================================================');
	      PRINT('-------------------------------------------------');
	      PRINT('Loading CRM tables')
	      PRINT('-------------------------------------------------');
	      
	      SET @start_time = GETDATE();
	      PRINT('>>Truncating table: bronze.crm_cust_info')
	      TRUNCATE TABLE bronze.crm_cust_info;
	      
	      PRINT('>>Inserting data into: bronze.crm_cust_info') BULK
	      INSERT bronze.crm_cust_info
	      FROM   '/datasets/source_crm/cust_info.csv' WITH
	             (
	                    firstrow = 2,
	                    fieldterminator = ',',
	                    tablock
	             );
	      SET @end_time = GETDATE();
	      PRINT '>> Load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
	      PRINT '>> --------------------'
	      
	      SET @start_time = GETDATE();
	      PRINT('>>Truncating table: bronze.crm_prd_info')
	      TRUNCATE TABLE bronze.crm_prd_info;
	      
	      PRINT('>>Inserting data into: bronze.crm_prd_info') BULK
	      INSERT bronze.crm_prd_info
	      FROM   '/datasets/source_crm/prd_info.csv' WITH
	             (
	                    firstrow = 2,
	                    fieldterminator = ',',
	                    tablock
	             );
	      SET @end_time = GETDATE();
	      PRINT '>> Load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
	      PRINT '>> --------------------'
	      
	       SET @start_time = GETDATE();
	      PRINT('>>Truncating table: bronze.crm_sales_details')
	      TRUNCATE TABLE bronze.crm_sales_details;
	      
	      PRINT('>>Inserting data into: bronze.crm_sales_details') BULK
	      INSERT bronze.crm_sales_details
	      FROM   '/datasets/source_crm/sales_details.csv' WITH
	             (
	                    firstrow = 2,
	                    fieldterminator = ',',
	                    tablock
	             );
	      SET @end_time = GETDATE();
	      PRINT '>> Load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
	      PRINT '>> --------------------'
	      
	      PRINT('-------------------------------------------------');
	      PRINT('Loading ERP tables')
	      PRINT('-------------------------------------------------');
	      
	      SET @start_time = GETDATE();
	      PRINT('>>Truncating table: bronze.erp_cust_az12')
	      TRUNCATE TABLE bronze.erp_cust_az12;
	      
	      PRINT('>>Inserting data into: bronze.bronze.erp_cust_az12') BULK
	      INSERT bronze.erp_cust_az12
	      FROM   '/datasets/source_erp/cust_az12.csv' WITH
	             (
	                    firstrow = 2,
	                    fieldterminator = ',',
	                    ROWTERMINATOR = '0x0d0a',
	                    tablock
	             );
	      SET @end_time = GETDATE();
	      PRINT '>> Load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
	      PRINT '>> --------------------'
	      
	      SET @start_time = GETDATE();
	      PRINT('>>Truncating table: bronze.erp_loc_a101')
	      TRUNCATE TABLE bronze.erp_loc_a101;
	      
	      PRINT('>>Inserting data into: bronze.erp_loc_a101') BULK
	      INSERT bronze.erp_loc_a101
	      FROM   '/datasets/source_erp/loc_a101.csv' WITH
	             (
	                    firstrow = 2,
	                    fieldterminator = ',',
	                    ROWTERMINATOR = '0x0d0a',
	                    tablock
	             );
	      SET @end_time = GETDATE();
	      PRINT '>> Load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
	      PRINT '>> --------------------'
	      
	      SET @start_time = GETDATE();
	      PRINT('>>Truncating table: bronze.erp_px_cat_g1v2')
	      TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	      
	      PRINT('>>Inserting data into: bronze.erp_px_cat_g1v2') BULK
	      INSERT bronze.erp_px_cat_g1v2
	      FROM   '/datasets/source_erp/px_cat_g1v2.csv' WITH
	             (
	                    firstrow = 2,
	                    fieldterminator = ',',
	                    ROWTERMINATOR = '0x0d0a',
	                    tablock
	             );
	      SET @end_time = GETDATE();
	      PRINT '>> Load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';
	      PRINT '>> --------------------'
	      
	      
	      SET @batch_end_time = GETDATE();
	      PRINT '================================================='
	      PRINT 'Loading bronze layer is completed';
	      PRINT '>> Total Load duration: ' + CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds';
	      PRINT '================================================='
		END try
		BEGIN catch
		PRINT('=================================================');
		PRINT('ERROR LOADING BRONZE LAYER');
		PRINT 'Eror message:' + ERROR_MESSAGE();
		PRINT 'Eror number:' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Eror state:' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT('=================================================');
		END catch
	END
	
