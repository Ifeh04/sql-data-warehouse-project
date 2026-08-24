/*
===============================================================================
DDL Script : ddl_gold.sql
Layer      : Gold (Business-Ready Dimensional Model - Star Schema)
Database   : PostgreSQL (DataWareHouse)
===============================================================================
Script Purpose:
    Creates the gold layer as a star schema of views:
      - gold.dim_customers : reconciled customer dimension (CRM + ERP)
      - gold.dim_products  : current (non-discontinued) product dimension
      - gold.fact_sales    : sales fact linked to both dimensions

Business Rules:
    * Gender   : CRM is the master; ERP used only when CRM = 'N/A'.
    * Products : only the current version is exposed (prd_end_dt IS NULL).
    * Surrogate keys (customer_key, product_key) via ROW_NUMBER().
===============================================================================
*/

CREATE SCHEMA IF NOT EXISTS gold;

-- =============================================
-- Dimension: gold.dim_customers
-- Description: One row per customer; CRM attributes
--              reconciled with ERP birthdate, gender & country
-- =============================================
CREATE OR REPLACE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,  -- surrogate key
    ci.cst_id   AS customer_id,
    ci.cst_key  AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname  AS last_name,
    ci.cst_marital_status AS marital_status,
    CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr   -- CRM = master for gender
         ELSE COALESCE(ca.gen, 'N/A')                 -- ERP fallback
    END AS gendr,
    ci.cst_create_date AS create_date,
    ca.bdate AS birthdate,
    COALESCE(la.cntry, 'N/A') AS country
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  la ON ci.cst_key = la.cid;

-- =============================================
-- Dimension: gold.dim_products
-- Description: One row per current product version,
--              enriched with ERP category / subcategory
-- =============================================
CREATE OR REPLACE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,                                       -- surrogate key
    pn.prd_id   AS product_id,
    pn.prd_key  AS product_number,
    pn.prd_nm   AS product_name,
    pn.cat_id   AS category_id,
    pc.cat      AS category,
    pc.subcat   AS subcategory,
    pc.maintenance,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;   -- current (non-discontinued) products only

-- =============================================
-- Fact: gold.fact_sales
-- Description: Sales transactions linked to customer
--              and product dimensions via surrogate keys
-- =============================================
CREATE OR REPLACE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key,
    cu.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipment_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products  pr ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu ON sd.sls_cust_id = cu.customer_id;
