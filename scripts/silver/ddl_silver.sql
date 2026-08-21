/*
===============================================================================
DDL Script: ddl_silver.sql
Layer     : Silver
===============================================================================
*/

-- Ensure silver schema exists
CREATE SCHEMA IF NOT EXISTS silver;

-- =============================================
-- Table: silver.crm_cust_info
-- Source: bronze.crm_cust_info
-- =============================================
DROP TABLE IF EXISTS silver.crm_cust_info CASCADE;

CREATE TABLE silver.crm_cust_info (
    cst_id             INT,
    cst_key            VARCHAR(50),
    cst_firstname      VARCHAR(50),
    cst_lastname       VARCHAR(50),
    cst_marital_status VARCHAR(50),  
    cst_gndr           VARCHAR(50),  
    cst_create_date    DATE,
    dwh_create_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.crm_prd_info
-- Source: bronze.crm_prd_info
-- =============================================
DROP TABLE IF EXISTS silver.crm_prd_info CASCADE;

CREATE TABLE silver.crm_prd_info (
    prd_id          INT,
    cat_id          VARCHAR(50),     
    prd_key         VARCHAR(50),     
    prd_nm          VARCHAR(50),
    prd_cost        INT,           
    prd_line        VARCHAR(50),    
    prd_start_dt    DATE,
    prd_end_dt      DATE,           
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.crm_sales_details
-- Source: bronze.crm_sales_details
-- =============================================
DROP TABLE IF EXISTS silver.crm_sales_details CASCADE;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num     VARCHAR(50),
    sls_prd_key     VARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,           
    sls_ship_dt     DATE,            
    sls_due_dt      DATE,           
    sls_sales       INT,            
    sls_quantity    INT,
    sls_price       INT,             
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.erp_cust_az12
-- Source: bronze.erp_cust_az12
-- =============================================
DROP TABLE IF EXISTS silver.erp_cust_az12 CASCADE;

CREATE TABLE silver.erp_cust_az12 (
    cid             VARCHAR(50),     
    bdate           DATE,           
    gen             VARCHAR(50),    
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.erp_loc_a101
-- Source: bronze.erp_loc_a101
-- =============================================
DROP TABLE IF EXISTS silver.erp_loc_a101 CASCADE;

CREATE TABLE silver.erp_loc_a101 (
    cid             VARCHAR(50),    
    cntry           VARCHAR(50),     
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.erp_px_cat_g1v2
-- Source: bronze.erp_px_cat_g1v2
-- =============================================
DROP TABLE IF EXISTS silver.erp_px_cat_g1v2 CASCADE;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id              VARCHAR(50),
    cat             VARCHAR(50),
    subcat          VARCHAR(50),
    maintenance     VARCHAR(50),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Table: silver.data_quality_log
-- Description: Audit log of data quality issues found in bronze
--              and the corrective actions applied in silver
-- =============================================
DROP TABLE IF EXISTS silver.data_quality_log CASCADE;

CREATE TABLE silver.data_quality_log (
    log_id          SERIAL PRIMARY KEY,
    table_name      VARCHAR(100),
    column_name     VARCHAR(100),
    issue_type      VARCHAR(100),
    record_id       VARCHAR(50),
    original_value  VARCHAR(500),
    corrected_value VARCHAR(500),
    action_taken    VARCHAR(200),
    logged_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Verify all silver tables were created
-- =============================================
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'silver'
ORDER BY table_name;
