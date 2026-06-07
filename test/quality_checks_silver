/*
=============================================================
Script:  quality_checks_silver.sql
Author:  Antony Alvin Johnson
=============================================================
Purpose:
    Data quality checks run against Bronze and Silver layers
    before and after the silver load procedure.

    Checks include:
        - Duplicate and NULL primary key detection
        - Unwanted whitespace in string fields
        - Data standardisation (gender, marital status,
          product line, country)
        - Invalid or out-of-range date values
        - Referential integrity between tables
        - Business rule validation (sales = quantity * price)

Usage:
    Run after EXEC silver.load_silver to validate results.
=============================================================
*/

-- =============================================================
-- crm_cust_info
-- =============================================================

-- Check for duplicate or NULL primary keys
SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces in name fields
SELECT cst_firstname FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Check distinct values for standardisation (gender and marital status)
SELECT DISTINCT cst_gndr FROM bronze.crm_cust_info;
SELECT DISTINCT cst_marital_status FROM bronze.crm_cust_info;

-- =============================================================
-- crm_prd_info
-- =============================================================

-- Check for duplicate or NULL product IDs
SELECT prd_id, COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces in product name
SELECT prd_nm FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for NULLs or negative costs
SELECT prd_cost FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Check distinct product lines for standardisation
SELECT DISTINCT prd_line FROM bronze.crm_prd_info;

-- Check for invalid date orders (end date before start date)
SELECT * FROM bronze.crm_prd_info
WHERE prd_start_dt > TRY_CONVERT(DATE, prd_end_dt, 105);

-- Validate SCD Type 2 end date derivation using LEAD()
SELECT 
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    CONVERT(NVARCHAR(50), 
        DATEADD(DAY, -1,
            LEAD(TRY_CONVERT(DATE, prd_start_dt, 105)) 
            OVER (PARTITION BY prd_key ORDER BY TRY_CONVERT(DATE, prd_start_dt, 105))
        ), 105) AS prd_end_dt_derived,
    prd_end_dt
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509');

-- =============================================================
-- crm_sales_details
-- =============================================================

-- Check for unwanted spaces in order number
SELECT * FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Check referential integrity: product keys must exist in silver
SELECT * FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- Check referential integrity: customer IDs must exist in silver
SELECT * FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- Check for invalid date values (zero, wrong length, out of range)
SELECT NULLIF(sls_ship_dt, 0) AS sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0
   OR LEN(sls_ship_dt) != 8
   OR sls_ship_dt > 20500101
   OR sls_ship_dt < 19000101;

-- Check for invalid date orders (order date after ship or due date)
SELECT * FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Business rule: sales must equal quantity * price
-- Flags rows where values are NULL, negative, or inconsistent
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price,
    CASE WHEN sls_sales IS NULL OR sls_sales <= 0
              OR sls_sales != sls_quantity * ABS(sls_price)
         THEN sls_quantity * ABS(sls_price)
         ELSE sls_sales
    END AS sls_sales_corrected,
    CASE WHEN sls_price IS NULL OR sls_price <= 0
         THEN sls_sales / NULLIF(sls_quantity, 0)
         ELSE sls_price
    END AS sls_price_corrected
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_price <= 0 OR sls_quantity <= 0;

-- =============================================================
-- erp_cust_az12
-- =============================================================

-- Check for out-of-range birthdates (before 1926 or in the future)
SELECT DISTINCT TRY_CONVERT(DATE, bdate, 105) AS bdate
FROM bronze.erp_cust_az12
WHERE TRY_CONVERT(DATE, bdate, 105) < '1926-01-01'
   OR TRY_CONVERT(DATE, bdate, 105) > GETDATE();

-- Check distinct gender values after standardisation
SELECT DISTINCT gen FROM silver.erp_cust_az12;

-- =============================================================
-- erp_loc_a101
-- =============================================================

-- Check for customer IDs in ERP that do not exist in CRM
SELECT cid FROM bronze.erp_loc_a101
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Check distinct country values after standardisation
SELECT DISTINCT cntry FROM silver.erp_loc_a101
ORDER BY cntry;

-- =============================================================
-- erp_px_cat_g1v2
-- =============================================================

-- Check for unwanted spaces in category fields
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);

-- Check distinct category values
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;
