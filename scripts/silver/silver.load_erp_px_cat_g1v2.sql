CREATE OR REPLACE PROCEDURE silver.load_erp_px_cat_g1v2()
LANGUAGE plpgsql
AS $$
DECLARE
    row_count INT;
BEGIN
    TRUNCATE TABLE silver.erp_px_cat_g1v2 CASCADE;

    INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT id, cat, subcat, maintenance
    FROM bronze.erp_px_cat_g1v2;

    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE 'silver.erp_px_cat_g1v2 loaded: % rows', row_count;
END;
$$;
