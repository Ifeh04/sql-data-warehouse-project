CREATE OR REPLACE PROCEDURE silver.load_erp_loc_a101()
LANGUAGE plpgsql
AS $$
DECLARE
    row_count INT;
BEGIN
    TRUNCATE TABLE silver.erp_loc_a101 CASCADE;

    INSERT INTO silver.erp_loc_a101 (cid, cntry)
    SELECT
        REPLACE(cid, '-', ''),
        CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
             WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
             WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
             ELSE TRIM(cntry) END
    FROM bronze.erp_loc_a101;

    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE 'silver.erp_loc_a101 loaded: % rows', row_count;
END;
$$;
