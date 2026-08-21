CREATE OR REPLACE PROCEDURE silver.load_crm_cust_info()
LANGUAGE plpgsql
AS $$
DECLARE
    row_count INT;
BEGIN
    TRUNCATE TABLE silver.crm_cust_info CASCADE;

    INSERT INTO silver.crm_cust_info (
        cst_id, cst_key, cst_firstname, cst_lastname,
        cst_marital_status, cst_gndr, cst_create_date
    )
    SELECT 
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
             WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
             WHEN UPPER(TRIM(cst_marital_status)) = 'D' THEN 'Divorced'
             WHEN UPPER(TRIM(cst_marital_status)) = 'W' THEN 'Widowed'
             ELSE 'N/A' END,
        CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
             WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
             ELSE 'N/A' END,
        cst_create_date
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id ORDER BY cst_create_date DESC
            ) AS rn
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) ranked
    WHERE rn = 1;

    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE 'silver.crm_cust_info loaded: % rows', row_count;
END;
$$;
