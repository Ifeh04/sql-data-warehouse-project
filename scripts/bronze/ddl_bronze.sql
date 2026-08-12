CREATE  TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key VARCHAR(50),
    cst_firstname VARCHAR(50),
    cst_lastname VARCHAR(50),
    cst_marital_status VARCHAR(20),
    cst_gndr VARCHAR(10),
    cst_create_date DATE
);


CREATE TABLE bronze.crm_prd_info (
    prd_id INT,
    prd_key VARCHAR(50),
    prd_nm VARCHAR(100),
    prd_cost INT,
    prd_line VARCHAR(2),
    prd_start_dt DATE,
    prd_end_dt DATE
);


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

CREATE TABLE bronze.erp_cust_az12 (
    cid VARCHAR(50),
    bdate DATE,
    gen varchar(10)
);

CREATE TABLE bronze.erp_loc_a101 (
    cid VARCHAR(50),
    cntry varchar(50)
);

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id VARCHAR(50),
    cat VARCHAR(50),
    subcat VARCHAR(50),
    maintenance VARCHAR(50)
);

COPY bronze.crm_cust_info
FROM 'C:/Program Files\PostgreSQL/17/data/cust_info.csv'
WITH (
    FORMAT csv,
    DELIMITER ',',
    HEADER true
);

COPY bronze.crm_prd_info
FROM 'C:/Program Files\PostgreSQL/17/data/prd_info.csv'
WITH (      
    FORMAT csv,
    DELIMITER ',',
    HEADER true
);

COPY bronze.crm_sales_details
FROM 'C:/Program Files/PostgreSQL/17/data/sales_details.csv'
WITH (
    FORMAT csv,
    DELIMITER ',',
    HEADER true
);

copy bronze.erp_cust_az12
FROM 'C:/Program Files/PostgreSQL/17/data/cust_az12.csv'
WITH (
    FORMAT csv,
    DELIMITER ',',
    HEADER true
);

COPY bronze.erp_loc_a101
FROM 'C:/Program Files/PostgreSQL/17/data/loc_a101.csv'
WITH (
    FORMAT csv,
    DELIMITER ',',
    HEADER true
);

COPY bronze.erp_px_cat_g1v2
FROM 'C:/Program Files/PostgreSQL/17/data/px_cat_g1v2.csv'
WITH (
    FORMAT csv,
    DELIMITER ',',
    HEADER true
);
