CREATE OR REPLACE PROCEDURE silver.load_silver_layer()
LANGUAGE plpgsql
AS $$
BEGIN
    CALL silver.load_crm_cust_info();
    CALL silver.load_crm_prd_info();
    CALL silver.load_crm_sales_details();
    CALL silver.load_erp_cust_az12();
    CALL silver.load_erp_loc_a101();
    CALL silver.load_erp_px_cat_g1v2();
    RAISE NOTICE '✅ Silver layer load completed at %', CURRENT_TIMESTAMP;
END;
$$;
