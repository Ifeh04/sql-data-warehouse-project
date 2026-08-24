/*
===============================================================================
Test Script : quality_checks.sql
Purpose     : All data quality checks conducted during bronze -> silver cleaning
Database    : PostgreSQL (DataWareHouse)
===============================================================================
How To Use:
    - Run AFTER the silver layer load (CALL silver.load_silver_layer();).
    - [BRONZE] checks are DIAGNOSTIC: they document issues present in raw data.
    - [SILVER] checks marked "Expectation: 0 rows" must return nothing.
    - Profiling checks (SELECT DISTINCT) are for reviewing raw value domains.
===============================================================================
*/


-- ################################################################
-- TABLE 1: crm_cust_info (CRM - Customers)
-- ################################################################

-- [BRONZE] 1.1 Duplicate / NULL customer IDs (diagnostic - duplicates expected)
SELECT cst_id, COUNT(*) AS duplicate_count
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL
ORDER BY duplicate_count DESC;

-- [BRONZE] 1.2 Unwanted spaces in cst_key (expectation: 0 rows)
SELECT cst_key
FROM bronze.crm_cust_info
WHERE cst_key != TRIM(cst_key);

-- [BRONZE] 1.3 Profiling: raw marital status codes (review: S/M + spaces)
SELECT DISTINCT cst_marital_status FROM bronze.crm_cust_info;

-- [BRONZE] 1.4 Profiling: raw gender codes (review: M/F + spaces)
SELECT DISTINCT cst_gndr FROM bronze.crm_cust_info;

-- [BRONZE] 1.5 Deduplication logic preview: latest record per cst_id gets rn = 1
SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname)  AS cst_lastname,
    CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
         WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
         WHEN UPPER(TRIM(cst_marital_status)) = 'D' THEN 'Divorced'
         WHEN UPPER(TRIM(cst_marital_status)) = 'W' THEN 'Widowed'
         ELSE 'N/A' END AS cst_marital_status,
    CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
         WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
         ELSE 'N/A' END AS cst_gndr,
    cst_create_date,
    ROW_NUMBER() OVER (
        PARTITION BY cst_id ORDER BY cst_create_date DESC
    ) AS rn,
    CASE WHEN ROW_NUMBER() OVER (
              PARTITION BY cst_id ORDER BY cst_create_date DESC
         ) = 1 THEN TRUE ELSE FALSE END AS flag_last
FROM bronze.crm_cust_info;

-- [SILVER] 1.6 Duplicate customer IDs after dedup (expectation: 0 rows)
SELECT cst_id, COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- [SILVER] 1.7 Deduplication impact: bronze vs silver row counts
SELECT 'Bronze (raw)' AS layer, COUNT(*) AS row_count FROM bronze.crm_cust_info
UNION ALL
SELECT 'Silver (deduplicated)', COUNT(*) FROM silver.crm_cust_info;

-- [SILVER] 1.8 Unexpected standardized values (expectation: 0 rows)
SELECT *
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Single', 'Married', 'Divorced', 'Widowed', 'N/A')
   OR cst_gndr NOT IN ('Male', 'Female', 'N/A');


-- ################################################################
-- TABLE 2: crm_prd_info (CRM - Products)
-- ################################################################

-- [BRONZE] 2.1 Duplicate / NULL product IDs (diagnostic - duplicates = versions)
SELECT prd_id, COUNT(*) AS duplicate_count
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- [BRONZE] 2.2 NULL / negative product costs (diagnostic)
SELECT prd_id, prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- [BRONZE] 2.3 Profiling: raw product line codes (review: 'M '/'R '/'S '/'T '/empty)
SELECT DISTINCT prd_line FROM bronze.crm_prd_info;

-- [BRONZE] 2.4 Key splitting preview: cat_id / subcat extracted from prd_key
SELECT
    prd_id,
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7, 10) AS subcat_id,
    TRIM(prd_nm) AS prd_nm,
    COALESCE(prd_cost, 0) AS prd_cost
FROM bronze.crm_prd_info;

-- [BRONZE] 2.5 Date discrepancy summary: start date after end date
SELECT 
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE prd_start_dt > prd_end_dt) AS records_with_issues,
    ROUND(
        COUNT(*) FILTER (WHERE prd_start_dt > prd_end_dt) * 100.0 / COUNT(*), 
        2
    ) AS percentage_affected
FROM bronze.crm_prd_info;

-- [BRONZE] 2.6 Date discrepancy detail (all rows where start > end)
SELECT 
    prd_id, prd_key, prd_nm, prd_start_dt, prd_end_dt,
    CASE WHEN prd_start_dt > prd_end_dt THEN 'Invalid'
         WHEN prd_start_dt = prd_end_dt THEN 'Same Date'
         ELSE 'Valid' END AS date_status
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- [SILVER] 2.7 Invalid validity windows after correction (expectation: 0 rows)
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- [SILVER] 2.8 NULL / negative costs after COALESCE (expectation: 0 rows)
SELECT prd_id, prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- [SILVER] 2.9 Standardized product lines (review: Mountain/Road/Other Sales/Touring/N/A)
SELECT DISTINCT prd_line FROM silver.crm_prd_info ORDER BY prd_line;


-- ################################################################
-- TABLE 3: crm_sales_details (CRM - Sales Transactions)
-- ################################################################

-- [BRONZE] 3.1 Unwanted spaces in order numbers (expectation: 0 rows)
SELECT sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- [BRONZE] 3.2 Referential integrity: orphan product keys (expectation: 0 rows)
-- Note: compared bronze-to-bronze because silver keys are transformed (split)
SELECT *
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM bronze.crm_prd_info);

-- [BRONZE] 3.3 Referential integrity: orphan customer IDs (expectation: 0 rows)
SELECT *
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM bronze.crm_cust_info);

-- [BRONZE] 3.4 Invalid order dates (0, negative, or not 8 digits)
SELECT sls_ord_num, sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR LENGTH(sls_order_dt::TEXT) != 8;

-- [BRONZE] 3.5 Invalid ship dates (0, negative, or not 8 digits)
SELECT sls_ord_num, sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 OR LENGTH(sls_ship_dt::TEXT) != 8;

-- [BRONZE] 3.6 Invalid due dates (0, negative, or not 8 digits)
SELECT sls_ord_num, sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 OR LENGTH(sls_due_dt::TEXT) != 8;

-- [BRONZE] 3.7 Illogical date sequence (order date after ship/due date)
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- [BRONZE] 3.8 Sales/quantity/price anomalies (business rule: sales = qty * price)
SELECT DISTINCT
    sls_sales, sls_quantity, sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price < 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- [BRONZE] 3.9 Transformation preview: original vs corrected sales/price
SELECT DISTINCT
    sls_sales  AS old_sls_sales,
    sls_quantity,
    sls_price  AS old_sls_price,
    CASE WHEN sls_sales IS NULL OR sls_sales <= 0 
           OR sls_sales != sls_quantity * ABS(sls_price)
         THEN sls_quantity * ABS(sls_price)
         ELSE sls_sales END AS sls_sales,
    CASE WHEN sls_price IS NULL OR sls_price <= 0
         THEN sls_sales / NULLIF(sls_quantity, 0)
         ELSE sls_price END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price < 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- [SILVER] 3.10 Illogical date sequence after conversion (expectation: 0 rows)
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- [SILVER] 3.11 Rule violations after cleaning (expectation: 0 rows)
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_sales <= 0
   OR sls_price IS NULL OR sls_price <= 0;

-- [SILVER] 3.12 Rows with NULL dates (informational - invalid source dates -> NULL)
SELECT 
    COUNT(*) FILTER (WHERE sls_order_dt IS NULL) AS null_order_dt,
    COUNT(*) FILTER (WHERE sls_ship_dt  IS NULL) AS null_ship_dt,
    COUNT(*) FILTER (WHERE sls_due_dt   IS NULL) AS null_due_dt
FROM silver.crm_sales_details;


-- ################################################################
-- TABLE 4: erp_cust_az12 (ERP - Customer Attributes)
-- ################################################################

-- [BRONZE] 4.1 Keys not matching CRM after 'NAS' prefix removal (expectation: 0 rows)
SELECT cid, bdate, gen
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
           ELSE cid END
      NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info);

-- [BRONZE] 4.2 Implausible / future birth dates (diagnostic)
SELECT DISTINCT bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > CURRENT_TIMESTAMP;

-- [BRONZE] 4.3 Profiling: raw gender values (review inconsistent codes)
SELECT DISTINCT gen FROM bronze.erp_cust_az12;

-- [SILVER] 4.4 Future birth dates after cleaning (expectation: 0 rows)
SELECT *
FROM silver.erp_cust_az12
WHERE bdate > CURRENT_TIMESTAMP;

-- [SILVER] 4.5 Standardized gender domain (review: Male/Female/N/A)
SELECT DISTINCT gen FROM silver.erp_cust_az12 ORDER BY gen;


-- ################################################################
-- TABLE 5: erp_loc_a101 (ERP - Customer Location)
-- ################################################################

-- [BRONZE] 5.1 Keys not matching CRM after hyphen removal (expectation: 0 rows)
SELECT REPLACE(cid, '-', '') AS cid
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- [BRONZE] 5.2 Profiling: raw country codes (review: DE/US/USA/empty)
SELECT DISTINCT cntry FROM bronze.erp_loc_a101;

-- [SILVER] 5.3 Standardized countries (review: full names only)
SELECT DISTINCT cntry FROM silver.erp_loc_a101 ORDER BY cntry;


-- ################################################################
-- TABLE 6: erp_px_cat_g1v2 (ERP - Product Categories)
-- ################################################################

-- [BRONZE] 6.1 Category IDs missing from product table (expectation: 0 rows)
SELECT DISTINCT id
FROM bronze.erp_px_cat_g1v2
WHERE id NOT IN (SELECT cat_id FROM silver.crm_prd_info);

-- [BRONZE] 6.2 Unwanted spaces in categories (diagnostic)
SELECT id, cat
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat);

-- [BRONZE] 6.3 Unwanted spaces in subcategories (diagnostic)
SELECT id, subcat
FROM bronze.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat);

-- [BRONZE] 6.4 Profiling: raw category / subcategory / maintenance values
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;


-- ################################################################
-- SUMMARY: Bronze vs Silver Row Counts (All Tables)
-- ################################################################

SELECT table_name, bronze_rows, silver_rows
FROM (
    SELECT 'crm_cust_info' AS table_name,
           (SELECT COUNT(*) FROM bronze.crm_cust_info)   AS bronze_rows,
           (SELECT COUNT(*) FROM silver.crm_cust_info)   AS silver_rows
    UNION ALL
    SELECT 'crm_prd_info',
           (SELECT COUNT(*) FROM bronze.crm_prd_info),
           (SELECT COUNT(*) FROM silver.crm_prd_info)
    UNION ALL
    SELECT 'crm_sales_details',
           (SELECT COUNT(*) FROM bronze.crm_sales_details),
           (SELECT COUNT(*) FROM silver.crm_sales_details)
    UNION ALL
    SELECT 'erp_cust_az12',
           (SELECT COUNT(*) FROM bronze.erp_cust_az12),
           (SELECT COUNT(*) FROM silver.erp_cust_az12)
    UNION ALL
    SELECT 'erp_loc_a101',
           (SELECT COUNT(*) FROM bronze.erp_loc_a101),
           (SELECT COUNT(*) FROM silver.erp_loc_a101)
    UNION ALL
    SELECT 'erp_px_cat_g1v2',
           (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2),
           (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2)
) t
ORDER BY table_name;

-- Review logged data quality issues and corrective actions taken
SELECT * FROM silver.data_quality_log ORDER BY logged_at DESC;
