CREATE OR REPLACE PROCEDURE silver.load_erp_cust_az12()
LANGUAGE plpgsql
AS $$
DECLARE
    row_count INT;
BEGIN
    TRUNCATE TABLE silver.erp_cust_az12 CASCADE;

    INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
             ELSE cid END,
        CASE WHEN bdate > CURRENT_TIMESTAMP THEN NULL
             ELSE bdate END,
        CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
             WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
             ELSE 'N/A' END
    FROM bronze.erp_cust_az12;

    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE 'silver.erp_cust_az12 loaded: % rows', row_count;
END;
$$;
