CREATE OR REPLACE PROCEDURE silver.load_crm_prd_info()
LANGUAGE plpgsql
AS $$
DECLARE
    row_count INT;
BEGIN
    TRUNCATE TABLE silver.crm_prd_info CASCADE;

    INSERT INTO silver.crm_prd_info (
        prd_id, cat_id, prd_key, prd_nm, prd_cost,
        prd_line, prd_start_dt, prd_end_dt
    )
    SELECT
        prd_id::INTEGER,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
        TRIM(SUBSTRING(prd_key, 7, LENGTH(prd_key))),
        TRIM(prd_nm),
        COALESCE(prd_cost::INTEGER, 0),
        CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
             WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
             WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
             WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
             ELSE 'N/A' END,
        CAST(prd_start_dt AS DATE),
        CAST(LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key ORDER BY prd_start_dt
        ) - INTERVAL '1 day' AS DATE)
    FROM bronze.crm_prd_info;

    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE 'silver.crm_prd_info loaded: % rows', row_count;
END;
$$;
