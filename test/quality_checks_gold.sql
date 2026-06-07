/*
=============================================================
Script:  quality_checks_gold.sql
Author:  Antony Alvin Johnson
=============================================================
Purpose:
    Data quality checks for the Gold layer views.

    Checks include:
        - Duplicate customer keys in dim_customers
        - Gender resolution logic validation (CRM vs ERP)
        - Duplicate product keys in dim_products
        - Foreign key integrity in fact_sales

Usage:
    Run after Gold views are created to validate the star schema.
=============================================================
*/

-- =============================================================
-- dim_customers
-- =============================================================

-- Check for duplicate customer keys after joining CRM and ERP
SELECT cst_id, COUNT(*)
FROM (
    SELECT 
        ci.cst_id, ci.cst_key, ci.cst_firstname, ci.cst_lastname,
        ci.cst_marital_status, ci.cst_gndr, ci.cst_create_date,
        ca.bdate, ca.gen, la.cntry
    FROM silver.crm_cust_info ci
    LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
    LEFT JOIN silver.erp_loc_a101  la ON ci.cst_key = la.cid
) t
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- Validate gender resolution logic (CRM takes priority over ERP)
SELECT DISTINCT
    ci.cst_gndr,
    ca.gen,
    CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is master source for gender
         ELSE COALESCE(ca.gen, 'n/a')
    END AS resolved_gender
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  la ON ci.cst_key = la.cid
ORDER BY 1, 2;

-- Final view check
SELECT DISTINCT * FROM gold.dim_customers;

-- =============================================================
-- dim_products
-- =============================================================

-- Check distinct category combinations from joined silver tables
SELECT DISTINCT ct.cat, ct.subcat, ct.maintenance
FROM silver.crm_prd_info p
LEFT JOIN silver.erp_px_cat_g1v2 ct ON p.cat_id = ct.id;

-- Check for duplicate product keys (current products only)
SELECT prd_key, COUNT(*)
FROM (
    SELECT 
        p.prd_id, p.prd_key, p.prd_nm, p.cat_id,
        ct.cat, ct.subcat, ct.maintenance,
        p.prd_cost, p.prd_line, p.prd_start_dt
    FROM silver.crm_prd_info p
    LEFT JOIN silver.erp_px_cat_g1v2 ct ON p.cat_id = ct.id
    WHERE prd_end_dt IS NULL -- Current products only
) t
GROUP BY prd_key
HAVING COUNT(*) > 1;

-- Final view check
SELECT DISTINCT * FROM gold.dim_products;

-- =============================================================
-- fact_sales
-- =============================================================

-- Check foreign key integrity: all keys must resolve to a dimension
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products  p ON p.product_key  = f.product_key
WHERE c.customer_key IS NULL OR p.product_key IS NULL;
