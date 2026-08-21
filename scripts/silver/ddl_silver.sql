-- =============================================
-- Table: bronze.crm_cust_info
-- Description: Customer information from CRM system
-- =============================================
CREATE TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key VARCHAR(50),
    cst_firstname VARCHAR(50),
    cst_lastname VARCHAR(50),
    cst_marital_status VARCHAR(20),
    cst_gndr VARCHAR(10),
    cst_create_date DATE
);

-- =============================================
-- Table: bronze.crm_prd_info
-- Description: Product information from CRM system
-- =============================================
CREATE TABLE bronze.crm_prd_info (
    prd_id INT,
    prd_key VARCHAR(50),
    prd_nm VARCHAR(100),
    prd_cost INT,
    prd_line VARCHAR(2),
    prd_start_dt DATE,
    prd_end_dt DATE
);

-- =============================================
-- Table: bronze.crm_sales_details
-- Description: Sales transaction details from CRM system
-- =============================================
CREATE TABLE bronze.crm_sales_details(
    sls_ord_num VARCHAR(50),
    sls_prd_key VARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT
);

-- =============================================
-- Table: bronze.erp_cust_az12
-- Description: Customer data from ERP system
-- =============================================
CREATE TABLE bronze.erp_cust_az12 (
    cid VARCHAR(50),
    bdate DATE,
    gen VARCHAR(10)
);

-- =============================================
-- Table: bronze.erp_loc_a101
-- Description: Location data from ERP system
-- =============================================
CREATE TABLE bronze.erp_loc_a101 (
    cid VARCHAR(50),
    cntry VARCHAR(50)
);

-- =============================================
-- Table: bronze.erp_px_cat_g1v2
-- Description: Product category data from ERP system
-- =============================================
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id VARCHAR(50),
    cat VARCHAR(50),
    subcat VARCHAR(50),
    maintenance VARCHAR(50)
);

-- Verify all tables were created
SELECT table_schema, table_name 
FROM information_schema.tables 
WHERE table_schema = 'bronze'
ORDER BY table_name;


-- =============================================
-- Load Data into Bronze Layer Tables
-- Load Customer Info
-- =============================================
COPY bronze.crm_cust_info (
    cst_id, cst_key, cst_firstname, cst_lastname, 
    cst_marital_status, cst_gndr, cst_create_date
)
FROM 'C:/Program Files/PostgreSQL/17/data/cust_info.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);

-- =============================================
-- Load Product Info
-- =============================================
COPY bronze.crm_prd_info (
    prd_id, prd_key, prd_nm, prd_cost, 
    prd_line, prd_start_dt, prd_end_dt
)
FROM 'C:/Program Files/PostgreSQL/17/data/prd_info.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);

-- =============================================
-- Load Sales Details
-- =============================================
COPY bronze.crm_sales_details (
    sls_ord_num, sls_prd_key, sls_cust_id, 
    sls_order_dt, sls_ship_dt, sls_due_dt, 
    sls_sales, sls_quantity, sls_price
)
FROM 'C:/Program Files/PostgreSQL/17/data/sales_details.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);

-- =============================================
-- Load ERP Customer Data
-- =============================================
COPY bronze.erp_cust_az12 (cid, bdate, gen)
FROM 'C:/Program Files/PostgreSQL/17/data/cust_az12.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);

-- =============================================
-- Load ERP Location Data
-- =============================================
COPY bronze.erp_loc_a101 (cid, cntry)
FROM 'C:/Program Files/PostgreSQL/17/data/loc_a101.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);

-- =============================================
-- Load ERP Product Category Data
-- =============================================
COPY bronze.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
FROM 'C:/Program Files/PostgreSQL/17/data/px_cat_g1v2.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER true);


-- =============================================
-- Verify Data Load
-- =============================================

SELECT 'crm_cust_info' as table_name, COUNT(*) as row_count FROM bronze.crm_cust_info
UNION ALL SELECT 'crm_prd_info', COUNT(*) FROM bronze.crm_prd_info
UNION ALL SELECT 'crm_sales_details', COUNT(*) FROM bronze.crm_sales_details
UNION ALL SELECT 'erp_cust_az12', COUNT(*) FROM bronze.erp_cust_az12
UNION ALL SELECT 'erp_loc_a101', COUNT(*) FROM bronze.erp_loc_a101
UNION ALL SELECT 'erp_px_cat_g1v2', COUNT(*) FROM bronze.erp_px_cat_g1v2
ORDER BY table_name;


-- Ensure silver schema exists
CREATE SCHEMA IF NOT EXISTS silver;

-- =============================================
-- Table: silver.crm_cust_info
-- Description: Cleaned customer information
-- =============================================
DROP TABLE IF EXISTS silver.crm_cust_info CASCADE;

CREATE TABLE silver.crm_cust_info (
    cst_id INT,
    cst_key VARCHAR(50),
    cst_firstname VARCHAR(50),
    cst_lastname VARCHAR(50),
    cst_marital_status VARCHAR(50),
    cst_gndr VARCHAR(50),
    cst_create_date DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.crm_prd_info
-- Description: Cleaned product information
-- =============================================
DROP TABLE IF EXISTS silver.crm_prd_info CASCADE;

CREATE TABLE silver.crm_prd_info (
    prd_id INT,
    cat_id VARCHAR(50),
    prd_key VARCHAR(50),
    prd_nm VARCHAR(50),
    prd_cost INT,
    prd_line VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.crm_sales_details
-- Description: Cleaned sales transaction details
-- =============================================
DROP TABLE IF EXISTS silver.crm_sales_details CASCADE;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num VARCHAR(50),
    sls_prd_key VARCHAR(50),
    sls_cust_id INT,
    sls_order_dt DATE,
    sls_ship_dt DATE,
    sls_due_dt DATE,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.erp_loc_a101
-- Description: Cleaned location data
-- =============================================
DROP TABLE IF EXISTS silver.erp_loc_a101 CASCADE;

CREATE TABLE silver.erp_loc_a101 (
    cid VARCHAR(50),
    cntry VARCHAR(50),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.erp_cust_az12
-- Description: Cleaned ERP customer data
-- =============================================
DROP TABLE IF EXISTS silver.erp_cust_az12 CASCADE;

CREATE TABLE silver.erp_cust_az12 (
    cid VARCHAR(50),
    bdate DATE,
    gen VARCHAR(50),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.erp_px_cat_g1v2
-- Description: Cleaned product category data
-- =============================================
DROP TABLE IF EXISTS silver.erp_px_cat_g1v2 CASCADE;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id VARCHAR(50),
    cat VARCHAR(50),
    subcat VARCHAR(50),
     maintenance VARCHAR(50),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Verify all tables were created
SELECT table_schema, table_name 
FROM information_schema.tables 
WHERE table_schema = 'silver'
ORDER BY table_name;


-- ====================================================================
-- QUALITY CHECK 
-- ====================================================================

-- Check 1.1: Check for NULLs or Duplicates in Primary Key
-- Expectation: No results (0 rows)
SELECT 
    cst_id,
    COUNT(*) as duplicate_count
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;


-- The query below checks for the latest record for each customer based on the cst_create_date. It assigns a row number to each record partitioned by cst_id and ordered by cst_create_date in descending order. The latest record will have a row number of 1, and a flag is set to TRUE for the latest record and FALSE for others.
SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) as cst_firstname,
    TRIM(cst_lastname) as cst_lastname,
    CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
         WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
         ELSE 'N/A' 
    END as cst_marital_status,
    CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
         WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
         ELSE 'N/A'
    END as cst_gndr,
    cst_create_date,
    ROW_NUMBER() OVER (
        PARTITION BY cst_id 
        ORDER BY cst_create_date DESC
    ) as rn,
    CASE 
        WHEN ROW_NUMBER() OVER (
            PARTITION BY cst_id 
            ORDER BY cst_create_date DESC
        ) = 1 THEN TRUE 
        ELSE FALSE 
    END as flag_last
FROM bronze.crm_cust_info;

-- Data Stanardization & Consistency

SELECT cst_key
FROM bronze.crm_cust_info
WHERE cst_key != TRIM(cst_key);

SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info; 
 

-- Loading Silver Layer Tables with Cleaned Data

TRUNCATE TABLE silver.crm_cust_info CASCADE;

-- Insert cleaned and deduplicated data
INSERT INTO silver.crm_cust_info (
    cst_id, 
    cst_key, 
    cst_firstname, 
    cst_lastname, 
    cst_marital_status, 
    cst_gndr, 
    cst_create_date
    -- NOTE: dwh_create_date is auto-populated by DEFAULT CURRENT_TIMESTAMP
)
SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) as cst_firstname,
    TRIM(cst_lastname) as cst_lastname,
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        WHEN UPPER(TRIM(cst_marital_status)) = 'D' THEN 'Divorced'
        WHEN UPPER(TRIM(cst_marital_status)) = 'W' THEN 'Widowed'
        ELSE 'N/A' 
    END as cst_marital_status,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        ELSE 'N/A'
    END as cst_gndr,
    cst_create_date
    -- NOTE: rn and flag_last are NOT inserted (they're temporary)
FROM (
    SELECT 
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date,
        ROW_NUMBER() OVER (
            PARTITION BY cst_id 
            ORDER BY cst_create_date DESC
        ) as rn
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) ranked
WHERE rn = 1;  -- Only keep the most recent record per customer

-- Verify the load
SELECT 
    'Bronze' as layer, 
    COUNT(*) as row_count 
FROM bronze.crm_cust_info
UNION ALL
SELECT 
    'Silver', 
    COUNT(*) 
FROM silver.crm_cust_info;


-- Check for duplicates in silver (should return 0 rows)
SELECT 
    cst_id, 
    COUNT(*) as duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

SELECT * FROM silver.crm_cust_info;

-- Quality check for _crm_prd_info table

SELECT *
FROM bronze.crm_prd_info;

SELECT prd_id, 
COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL; 


SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;

SELECT
    prd_id,
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id,
    SUBSTRING(prd_key, 7, 10) as subcat_id,
    TRIM(prd_nm) as prd_nm,
    COALESCE(prd_cost, 0) AS prd_cost,
    CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
         WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
         WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'other sales'
         WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
         ELSE 'N/A'
    END as prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info;

-- =============================================
-- Quality Check: Identifying Date Discrepancies
-- =============================================

-- Count total records with date issues
SELECT 
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE prd_start_dt > prd_end_dt) as records_with_issues,
    ROUND(
        COUNT(*) FILTER (WHERE prd_start_dt > prd_end_dt) * 100.0 / COUNT(*), 
        2
    ) as percentage_affected
FROM bronze.crm_prd_info;

SELECT 
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,
    CASE 
        WHEN prd_start_dt > prd_end_dt THEN 'Invalid'
        WHEN prd_start_dt = prd_end_dt THEN 'Same Date'
        ELSE '✅ Valid'
    END as date_status
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- =============================================
-- Create Data Quality Log Table
-- =============================================
CREATE TABLE IF NOT EXISTS silver.data_quality_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100),
    column_name VARCHAR(100),
    issue_type VARCHAR(100),
    record_id VARCHAR(50),
    original_value VARCHAR(500),
    corrected_value VARCHAR(500),
    action_taken VARCHAR(200),
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Log the Date Issues

INSERT INTO silver.data_quality_log (
    table_name, column_name, issue_type, 
    record_id, original_value, corrected_value, action_taken
)
SELECT 
    'bronze.crm_prd_info' as table_name,
    'prd_start_dt, prd_end_dt' as column_name,
    'Start_Date_After_End_Date' as issue_type,
    prd_id::VARCHAR as record_id,
    CONCAT(prd_start_dt::TEXT, ' > ', prd_end_dt::TEXT) as original_value,
    CONCAT(prd_end_dt::TEXT, ' < ', prd_start_dt::TEXT) as corrected_value,
    'Dates swapped during silver transformation' as action_taken
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- View the log
SELECT * FROM silver.data_quality_log LIMIT 10;


--- Loading Silver Layer Table for Product Information with Corrected Dates

INSERT INTO silver.crm_prd_info (
    prd_id, 
    cat_id, 
    prd_key, 
    prd_nm, 
    prd_cost,
    prd_line, 
    prd_start_dt, 
    prd_end_dt,
    dwh_create_date 
)
SELECT
    prd_id::INTEGER as prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    TRIM(SUBSTRING(prd_key, 7, LENGTH(prd_key))) AS prd_key,
    TRIM(prd_nm) as prd_nm,
    COALESCE(prd_cost::INTEGER, 0) AS prd_cost,
    CASE 
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'N/A'
    END as prd_line,
    CAST(prd_start_dt AS DATE) as prd_start_dt,
    CAST(
        LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key 
            ORDER BY prd_start_dt
        ) - INTERVAL '1 day' 
    AS DATE) as prd_end_dt,
    CURRENT_TIMESTAMP as dwh_create_date
FROM bronze.crm_prd_info;


SELECT 
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM silver.crm_prd_info
ORDER BY prd_id;

SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

--- Data Quality Check for Sales Details

SELECT *
FROM bronze.crm_sales_details;

SELECT *
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

SELECT *
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

SELECT *
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- Change date format from INT to DATE for sales details

SELECT 
sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt < 0;

SELECT
sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0;

SELECT
sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0;

SELECT 
sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0;

-- Making 0 dates NULL
SELECT 
NULLIF(sls_order_dt, 0) as sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0;

SELECT 
NULLIF(sls_order_dt, 0) as sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR LENGTH(sls_order_dt::TEXT) != 8;

SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

SELECT DIsTINCT
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <0
ORDER BY sls_sales, sls_quantity, sls_price

-- Transfprming invalid data
SELECT DISTINCT
    sls_sales  AS old_sls_sales,
    sls_quantity,
    sls_price  AS old_sls_price,
    CASE 
        WHEN sls_sales IS NULL 
          OR sls_sales <= 0 
          OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    CASE 
        WHEN sls_price IS NULL OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price < 0
ORDER BY sls_sales, sls_quantity, sls_price;   

-- Should return 0 rows (all rows now consistent)
SELECT COUNT(*) AS inconsistent_rows
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_sales <= 0
   OR sls_price IS NULL OR sls_price <= 0;




SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt <= 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
    ELSE CASt(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt,
CASE WHEN sls_ship_dt <= 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
    ELSE CASt(CAST(sls_ship_dt AS VARCHAR) AS DATE)
    END AS sls_ship_dt,
CASE WHEN sls_due_dt <= 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
    ELSE CASt(CAST(sls_due_dt AS VARCHAR) AS DATE)
    END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
     THEN sls_quantity * ABS(sls_price)
     ELSE sls_sales
    END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <= 0
     THEN sls_sales / NULLIF(sls_quantity, 0)
     ELSE sls_price
    END AS sls_price,
sls_quantity 
FROM bronze.crm_sales_details;


-- Load  sales details into silver table

TRUNCATE TABLE silver.crm_sales_details CASCADE;


INSERT INTO silver.crm_sales_details (
    sls_ord_num, sls_prd_key, sls_cust_id,
    sls_order_dt, sls_ship_dt, sls_due_dt,
    sls_sales, sls_quantity, sls_price
)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt <= 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
    ELSE CASt(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt,
CASE WHEN sls_ship_dt <= 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
    ELSE CASt(CAST(sls_ship_dt AS VARCHAR) AS DATE)
    END AS sls_ship_dt,
CASE WHEN sls_due_dt <= 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
    ELSE CASt(CAST(sls_due_dt AS VARCHAR) AS DATE)
    END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
     THEN sls_quantity * ABS(sls_price)
     ELSE sls_sales
    END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <= 0
     THEN sls_sales / NULLIF(sls_quantity, 0)
     ELSE sls_price
    END AS sls_price,
sls_quantity 
FROM bronze.crm_sales_details;


-- Data quality checks

SELECT * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

SELECT *
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_sales <= 0
   OR sls_price IS NULL OR sls_price <= 0;

SELECT * FROM silver.crm_sales_details;

-- Inspecting the erp.cust.az12 data

SELECT * FROM bronze.erp_cust_az12;

SELECT * FROM silver.crm_cust_info;

SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
    ELSE cid
    END AS cid,
CASE WHEN bdate > CURRENT_TIMESTAMP THEN NULL
    ELSE bdate
    END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
    WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
    ELSE 'N/A'
END AS gen
FROM bronze.erp_cust_az12;

-- Checking to see if all the cid matched cst_key
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
    ELSE cid
    END AS cid,
bdate,
gen
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
    ELSE cid
END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)


SELECT DISTINCT 
bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > CURRENT_TIMESTAMP

SELECT DISTINCT gen
FROM bronze.erp_cust_az12

-- Insearting into silver later

INSERT INTO silver.erp_cust_az12
(cid,
bdate,
gen
)
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
    ELSE cid
    END AS cid,
CASE WHEN bdate > CURRENT_TIMESTAMP THEN NULL
    ELSE bdate
    END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
    WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
    ELSE 'N/A'
END AS gen
FROM bronze.erp_cust_az12;

SELECT * FROM silver.erp_cust_az12;

-- Inspecting the erp_loc_a101 data

SELECT * FROM bronze.erp_loc_a101;

SELECT * FROM silver.crm_cust_info;

SELECT 
REPLACE(cid, '-', '') as cid
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info)

SELECT DISTINCT
cntry
FROM bronze.erp_loc_a101

SELECT DISTINCT
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
    WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
    WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
    ELSE TRIM(cntry) 
END AS cntry
FROM bronze.erp_loc_a101;

-- Loading data into silver layer

INSERT INTO silver.erp_loc_a101
(cid,
cntry
)
SELECT 
REPLACE(cid, '-', '') as cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
    WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
    WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
    ELSE TRIM(cntry) 
END AS cntry
FROM bronze.erp_loc_a101;

SELECT * FROM silver.erp_loc_a101;

-- Inspecting the erp_px_cat_g1v

SELECT * FROM bronze.erp_px_cat_g1v2;

SELECT * FROM silver.crm_prd_info;

SELECT DISTINCT
id
FROM bronze.erp_px_cat_g1v2
WHERE id NOT IN (SELECT cat_id FROM silver.crm_prd_info);

SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat);

SELECT DISTINCT
cat
FROM bronze.erp_px_cat_g1v2;

SELECT * FROM bronze.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat);

SELECT DISTINCT
subcat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT
maintenance
FROM bronze.erp_px_cat_g1v2;

-- loading data into silver layer

INSERT INTO silver.erp_px_cat_g1v2
(id, cat, subcat, maintenance)
SELECT id, cat, subcat, maintenance
FROM bronze.erp_px_cat_g1v2;

SELECT * FROM silver.erp_px_cat_g1v2;

