/*
==================================
-- Create Database 'DataWarehouse'
==================================


About Script:
This script create new Database DataWarehouse and three schemas:
-bronze
-silver
-gold

Warning: 
Please make double check, because this script will drop the entire DataWarehouse if it exists.


*/
use master;

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END

CREATE DATABASE DataWarehouse;

USE DataWarehouse;

CREATE SCHEMA bronze;

CREATE SCHEMA silver;

CREATE SCHEMA gold;


