# Data Catalog — DataWareHouse (Formula-Free Sales & Customer Analytics)

## Overview

This project follows the **Medallion Architecture** on PostgreSQL:

| Layer  | Purpose                                                        | Objects                          |
|--------|----------------------------------------------------------------|----------------------------------|
| Bronze | Raw data loaded as-is from source systems (no cleaning)        | 6 tables                         |
| Silver | Cleaned, deduplicated & standardized data (per-source truth)   | 6 tables + data_quality_log      |
| Gold   | Business-ready star schema for analytics & reporting           | 3 views (2 dimensions + 1 fact)  |

**Source Systems:**
- **CRM** → `cust_info.csv`, `prd_info.csv`, `sales_details.csv`
- **ERP** → `cust_az12.csv`, `loc_a101.csv`, `px_cat_g1v2.csv`

```
 CRM / ERP CSVs ──COPY──▶ BRONZE ──clean/dedup/standardize──▶ SILVER ──join/reconcile──▶ GOLD
                              (raw)                              (trusted)              (star schema)
```

---

## 1. BRONZE LAYER (Raw / Landing Zone)

### 1.1 bronze.crm_cust_info
**Purpose:** Raw customer information from the CRM system.
**Source:** `cust_info.csv`
**Known quality issues (resolved in Silver):** duplicate `cst_id` versions, untrimmed names, coded marital status/gender values.

| Column Name        | Data Type    | Description |
|--------------------|--------------|-------------|
| cst_id             | INT          | Customer ID. Not unique — multiple versions exist per customer over time. |
| cst_key            | VARCHAR(50)  | Alphanumeric customer business key; used to link with ERP tables. |
| cst_firstname      | VARCHAR(50)  | Customer first name; may contain leading/trailing spaces. |
| cst_lastname       | VARCHAR(50)  | Customer last name; may contain leading/trailing spaces. |
| cst_marital_status | VARCHAR(20)  | Raw coded value (e.g., 'S', 'M') possibly with trailing spaces. |
| cst_gndr           | VARCHAR(10)  | Raw coded value ('M' / 'F'). |
| cst_create_date    | DATE         | Record creation date; used to identify the latest customer version. |

### 1.2 bronze.crm_prd_info
**Purpose:** Raw product information from the CRM system.
**Source:** `prd_info.csv`
**Known quality issues (resolved in Silver):** NULL costs, coded product lines, category embedded in `prd_key`, and `prd_start_dt` stored **after** `prd_end_dt` (invalid validity window).

| Column Name  | Data Type    | Description |
|--------------|--------------|-------------|
| prd_id       | INT          | Product ID. Duplicates represent product versions over time. |
| prd_key      | VARCHAR(50)  | Full product key; first 5 characters encode the category (e.g., 'AC-HE-...'). |
| prd_nm       | VARCHAR(100) | Descriptive product name (type, color, size). |
| prd_cost     | INT          | Product cost; may contain NULLs. |
| prd_line     | VARCHAR(2)   | Raw product line code ('M '/'R '/'S '/'T ') or empty string. |
| prd_start_dt | DATE         | Version start date. NOTE: later than `prd_end_dt` in source (invalid). |
| prd_end_dt   | DATE         | Version end date. NOTE: earlier than `prd_start_dt` in source (invalid). |

### 1.3 bronze.crm_sales_details
**Purpose:** Raw sales transaction line items from the CRM system.
**Source:** `sales_details.csv`
**Known quality issues (resolved in Silver):** dates stored as INT with 0/negative/wrong-length values; NULL/negative sales & prices; business rule `sales = quantity × price` violated; hyphens in order numbers.

| Column Name  | Data Type   | Description |
|--------------|-------------|-------------|
| sls_ord_num  | VARCHAR(50) | Sales order number containing a hyphen (e.g., 'AW-00011003'). |
| sls_prd_key  | VARCHAR(50) | Product key reference → `crm_prd_info.prd_key`. |
| sls_cust_id  | INT         | Customer ID reference → `crm_cust_info.cst_id`. |
| sls_order_dt | INT         | Order date as integer YYYYMMDD; may be 0, negative, or wrong length. |
| sls_ship_dt  | INT         | Ship date as integer YYYYMMDD; same issues as order date. |
| sls_due_dt   | INT         | Due date as integer YYYYMMDD; same issues as order date. |
| sls_sales    | INT         | Line sales amount; may be NULL/0/negative or mismatched with qty × price. |
| sls_quantity | INT         | Units ordered. |
| sls_price    | INT         | Unit price; may be NULL or negative. |

### 1.4 bronze.erp_cust_az12
**Purpose:** Raw customer demographic attributes from the ERP system.
**Source:** `cust_az12.csv`
**Known quality issues (resolved in Silver):** 'NAS' prefix on some keys, future birth dates, inconsistent gender values.

| Column Name | Data Type   | Description |
|-------------|-------------|-------------|
| cid         | VARCHAR(50) | Customer key; some values prefixed with 'NAS' (must be stripped). |
| bdate       | DATE        | Birth date; may contain future dates (invalid). |
| gen         | VARCHAR(10) | Gender; inconsistent codes and spellings (M/F/Male/Female). |

### 1.5 bronze.erp_loc_a101
**Purpose:** Raw customer country information from the ERP system.
**Source:** `loc_a101.csv`
**Known quality issues (resolved in Silver):** hyphens in keys, mixed country codes and empty strings.

| Column Name | Data Type   | Description |
|-------------|-------------|-------------|
| cid         | VARCHAR(50) | Customer key containing hyphens (must be removed to match `cst_key`). |
| cntry       | VARCHAR(50) | Country as mixed codes (DE / US / USA) or empty string. |

### 1.6 bronze.erp_px_cat_g1v2
**Purpose:** Raw product category reference data from the ERP system.
**Source:** `px_cat_g1v2.csv`

| Column Name | Data Type   | Description |
|-------------|-------------|-------------|
| id          | VARCHAR(50) | Category ID; matches the `cat_id` pattern derived in Silver. |
| cat         | VARCHAR(50) | Broad product category (e.g., Bikes, Components). |
| subcat      | VARCHAR(50) | Detailed subcategory within the category. |
| maintenance | VARCHAR(50) | Maintenance indicator for the category. |

---

## 2. SILVER LAYER (Cleaned & Standardized)

> Every Silver table carries a `dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP` audit column recording when the row was loaded.

### 2.1 silver.crm_cust_info
**Purpose:** Cleaned, deduplicated customer master (one row per customer).
**Transformations applied:** latest record kept per `cst_id` (ROW_NUMBER by `cst_create_date DESC`); names trimmed; marital status standardized (Single/Married/Divorced/Widowed/N/A); gender standardized (Male/Female/N/A).

| Column Name        | Data Type   | Description |
|--------------------|-------------|-------------|
| cst_id             | INT         | Customer ID — now unique (duplicates removed). |
| cst_key            | VARCHAR(50) | Customer business key (join key to ERP tables). |
| cst_firstname      | VARCHAR(50) | Trimmed first name. |
| cst_lastname       | VARCHAR(50) | Trimmed last name. |
| cst_marital_status | VARCHAR(50) | Standardized: Single / Married / Divorced / Widowed / N/A. |
| cst_gndr           | VARCHAR(50) | Standardized: Male / Female / N/A. |
| cst_create_date    | DATE        | Record creation date of the retained (latest) version. |
| dwh_create_date    | TIMESTAMP   | Audit: load timestamp into the warehouse. |

### 2.2 silver.crm_prd_info
**Purpose:** Cleaned product versions with derived category keys and corrected validity windows.
**Transformations applied:** `cat_id` derived from first 5 key characters ('-' → '_'); `prd_key` shortened (position 7+); NULL cost → 0; product line standardized (Mountain/Road/Other Sales/Touring/N/A); `prd_end_dt` re-derived as *next version's start date − 1 day* (NULL = currently active version).

| Column Name     | Data Type   | Description |
|-----------------|-------------|-------------|
| prd_id          | INT         | Product ID (one row per version). |
| cat_id          | VARCHAR(50) | Derived category ID (e.g., 'AC_HE'); joins to `erp_px_cat_g1v2.id`. |
| prd_key         | VARCHAR(50) | Shortened product key (e.g., 'HL-U509-R'); shared across versions. |
| prd_nm          | VARCHAR(50) | Trimmed product name. |
| prd_cost        | INT         | Product cost; NULLs replaced with 0. |
| prd_line        | VARCHAR(50) | Standardized: Mountain / Road / Other Sales / Touring / N/A. |
| prd_start_dt    | DATE        | Version start date. |
| prd_end_dt      | DATE        | Corrected version end date; NULL = active product. |
| dwh_create_date | TIMESTAMP   | Audit: load timestamp. |

### 2.3 silver.crm_sales_details
**Purpose:** Cleaned sales transactions with valid dates and consistent amounts.
**Transformations applied:** INT dates converted to DATE (0/negative/wrong-length → NULL); sales re-derived as `quantity × |price|` when NULL/≤0/mismatched; price re-derived as `sales ÷ quantity` when NULL/≤0 (negatives corrected).

| Column Name     | Data Type   | Description |
|-----------------|-------------|-------------|
| sls_ord_num     | VARCHAR(50) | Sales order number. |
| sls_prd_key     | VARCHAR(50) | Product key reference. |
| sls_cust_id     | INT         | Customer ID reference. |
| sls_order_dt    | DATE        | Order date (invalid source values → NULL). |
| sls_ship_dt     | DATE        | Ship date (invalid source values → NULL). |
| sls_due_dt      | DATE        | Due date (invalid source values → NULL). |
| sls_sales       | INT         | Corrected line sales amount (business rule enforced). |
| sls_quantity    | INT         | Units ordered. |
| sls_price       | INT         | Corrected unit price (positive; NULLs derived). |
| dwh_create_date | TIMESTAMP   | Audit: load timestamp. |

### 2.4 silver.erp_cust_az12
**Purpose:** Cleaned ERP customer demographics.
**Transformations applied:** 'NAS' prefix stripped from keys; future birth dates → NULL; gender standardized (Male/Female/N/A).

| Column Name     | Data Type   | Description |
|-----------------|-------------|-------------|
| cid             | VARCHAR(50) | Customer key, prefix removed — now matches `cst_key`. |
| bdate           | DATE        | Birth date; future dates nulled. |
| gen             | VARCHAR(50) | Standardized: Male / Female / N/A. |
| dwh_create_date | TIMESTAMP   | Audit: load timestamp. |

### 2.5 silver.erp_loc_a101
**Purpose:** Cleaned ERP customer country data.
**Transformations applied:** hyphens removed from keys; country codes standardized to full names (Germany / United States / N/A).

| Column Name     | Data Type   | Description |
|-----------------|-------------|-------------|
| cid             | VARCHAR(50) | Customer key, hyphens removed — now matches `cst_key`. |
| cntry           | VARCHAR(50) | Standardized country name. |
| dwh_create_date | TIMESTAMP   | Audit: load timestamp. |

### 2.6 silver.erp_px_cat_g1v2
**Purpose:** Product category reference data (carried forward for joins).

| Column Name     | Data Type   | Description |
|-----------------|-------------|-------------|
| id              | VARCHAR(50) | Category ID. |
| cat             | VARCHAR(50) | Broad product category. |
| subcat          | VARCHAR(50) | Product subcategory. |
| maintenance     | VARCHAR(50) | Maintenance indicator. |
| dwh_create_date | TIMESTAMP   | Audit: load timestamp. |

### 2.7 silver.data_quality_log
**Purpose:** Audit trail of data quality issues found in Bronze and the corrective actions applied in Silver.

| Column Name     | Data Type    | Description |
|-----------------|--------------|-------------|
| log_id          | SERIAL (PK)  | Auto-generated log entry ID. |
| table_name      | VARCHAR(100) | Source table where the issue was found. |
| column_name     | VARCHAR(100) | Column(s) affected. |
| issue_type      | VARCHAR(100) | Issue classification (e.g., 'Start_Date_After_End_Date'). |
| record_id       | VARCHAR(50)  | ID of the affected record. |
| original_value  | VARCHAR(500) | Value as received in Bronze. |
| corrected_value | VARCHAR(500) | Value after Silver transformation. |
| action_taken    | VARCHAR(200) | Description of the corrective action. |
| logged_at       | TIMESTAMP    | When the issue was logged. |

---

## 3. GOLD LAYER (Business-Ready Star Schema)

### 3.1 gold.dim_customers (view)
**Purpose:** One row per customer, enriched with ERP demographics and geography.
**Business rules:** CRM is the master for gender; ERP gender used only when CRM = 'N/A'; missing country → 'N/A'.

| Column Name    | Data Type   | Description |
|----------------|-------------|-------------|
| customer_key   | INT         | Surrogate key (ROW_NUMBER) uniquely identifying the customer. |
| customer_id    | INT         | Natural customer ID (`cst_id`). |
| customer_number| VARCHAR(50) | Customer business key (`cst_key`). |
| first_name     | VARCHAR(50) | Customer first name. |
| last_name      | VARCHAR(50) | Customer last name. |
| marital_status | VARCHAR(50) | Standardized marital status. |
| gendr          | VARCHAR(50) | Reconciled gender (CRM master, ERP fallback): Male / Female / N/A. |
| create_date    | DATE        | Customer record creation date. |
| birthdate      | DATE        | Birth date from ERP (future dates nulled). |
| country        | VARCHAR(50) | Standardized country of residence. |

### 3.2 gold.dim_products (view)
**Purpose:** One row per **currently active** product, enriched with category details.
**Business rules:** only non-discontinued versions exposed (`prd_end_dt IS NULL`).

| Column Name  | Data Type   | Description |
|--------------|-------------|-------------|
| product_key  | INT         | Surrogate key (ROW_NUMBER) uniquely identifying the product. |
| product_id   | INT         | Natural product ID (`prd_id`). |
| product_number| VARCHAR(50)| Shortened product key; join key from `fact_sales`. |
| product_name | VARCHAR(50) | Descriptive product name. |
| category_id  | VARCHAR(50) | Derived category ID linking to ERP categories. |
| category     | VARCHAR(50) | Broad classification (e.g., Bikes, Components). |
| subcategory  | VARCHAR(50) | Detailed classification within the category. |
| maintenance  | VARCHAR(50) | Maintenance indicator. |
| cost         | INT         | Product cost (NULLs → 0). |
| product_line | VARCHAR(50) | Standardized product line (Road / Mountain / Touring / Other Sales). |
| start_date   | DATE        | Date the product version became available. |

### 3.3 gold.fact_sales (view)
**Purpose:** Sales transaction line items linked to customer and product dimensions via surrogate keys.

| Column Name   | Data Type   | Description |
|---------------|-------------|-------------|
| order_number  | VARCHAR(50) | Sales order number (e.g., 'AW-00011003'). |
| product_key   | INT         | Surrogate key → `dim_products.product_key`. |
| customer_key  | INT         | Surrogate key → `dim_customers.customer_key`. |
| order_date    | DATE        | Date the order was placed. |
| shipment_date | DATE        | Date the order was shipped. |
| due_date      | DATE        | Date payment was due. |
| sales         | INT         | Corrected total sales amount for the line item. |
| quantity      | INT         | Units ordered. |
| price         | INT         | Corrected price per unit. |

---

## 4. Key Business Rules Summary

| # | Rule | Layer Applied |
|---|------|---------------|
| 1 | Keep only the latest customer record per `cst_id` | Silver |
| 2 | Product end date = next version start − 1 day; NULL = active | Silver |
| 3 | `sales = quantity × price` enforced (derive missing/invalid side) | Silver |
| 4 | CRM = master for gender; ERP = fallback | Gold |
| 5 | Only active products exposed in `dim_products` | Gold |
| 6 | All cross-system conflicts & fixes logged in `data_quality_log` | Silver |
