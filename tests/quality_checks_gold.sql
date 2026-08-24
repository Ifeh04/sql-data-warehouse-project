-- ################################################################
-- GOLD LAYER CHECKS (Star Schema Validation)
-- ################################################################

-- [GOLD] G.1 Orphan fact rows - model connectivity (expectation: 0 rows)
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products  p ON p.product_key  = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;

-- [GOLD] G.2 Surrogate key uniqueness - customers (expectation: 0 rows)
SELECT customer_key, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- [GOLD] G.3 Surrogate key uniqueness - products (expectation: 0 rows)
SELECT product_key, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- [GOLD] G.4 Products missing category (expectation: 0 rows)
SELECT COUNT(*) AS products_without_category
FROM gold.dim_products
WHERE category IS NULL;

-- [GOLD] G.5 Business rule holds in fact (expectation: 0 rows)
SELECT COUNT(*) AS inconsistent_sales
FROM gold.fact_sales
WHERE sales != quantity * price;
