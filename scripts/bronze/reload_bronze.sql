-- =============================================
-- Script: reload_bronze.sql
-- Purpose: Truncate and Reload Bronze Layer
-- Database: PostgreSQL
-- =============================================

-- 1. Truncate all tables (Clear old data)
-- Use CASCADE if there are foreign key dependencies
TRUNCATE TABLE bronze.crm_cust_info CASCADE;
TRUNCATE TABLE bronze.crm_prd_info CASCADE;
TRUNCATE TABLE bronze.crm_sales_details CASCADE;
TRUNCATE TABLE bronze.erp_cust_az12 CASCADE;
TRUNCATE TABLE bronze.erp_loc_a101 CASCADE;
TRUNCATE TABLE bronze.erp_px_cat_g1v2 CASCADE;

-- 2. Reload data from CSV files
-- Note: Paths must be accessible by the PostgreSQL SERVER
COPY bronze.crm_cust_info
FROM 'C:/Program Files/PostgreSQL/17/data/cust_info.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);

COPY bronze.crm_prd_info
FROM 'C:/Program Files/PostgreSQL/17/data/prd_info.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);

COPY bronze.crm_sales_details
FROM 'C:/Program Files/PostgreSQL/17/data/sales_details.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);

COPY bronze.erp_cust_az12
FROM 'C:/Program Files/PostgreSQL/17/data/cust_az12.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);

COPY bronze.erp_loc_a101
FROM 'C:/Program Files/PostgreSQL/17/data/loc_a101.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);

COPY bronze.erp_px_cat_g1v2
FROM 'C:/Program Files/PostgreSQL/17/data/px_cat_g1v2.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);
