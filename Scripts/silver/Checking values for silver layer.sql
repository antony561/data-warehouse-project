SELECT * FROM bronze.crm_cust_info
-- crm_cust_info--
--Checking for Duplicates
SELECT cst_id, COUNT(*) FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for Duplicates or Nulls in primary key
SELECT 
cst_id, 
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id is null;

--checking unwanted  spaces on firtname & last name
SELECT cst_firstname FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

--Data standarlization gender and marital
SELECT DISTINCT(cst_gndr) FROM bronze.crm_cust_info;
SELECT DISTINCT(cst_marital_status) FROM bronze.crm_cust_info;

-----crm_prd_info-----

SELECT * FROM bronze.crm_prd_info;

SELECT prd_id, COUNT(*) FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT (*) > 1 OR prd_id IS NULL

--checking unwanted  spaces on prd_nm
SELECT prd_nm FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

--check for nulls or negative number
SELECT prd_cost FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost is null;

--Data Standarlisation and Normalization
SELECT DISTINCT prd_line FROM bronze.crm_prd_info

--check for invalid date orders( end date should not be earlier than start date)
SELECT * FROM bronze.crm_prd_info 
WHERE prd_start_dt > TRY_CONVERT(DATE, prd_end_dt, 105);

SELECT 
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    -- Convert result to DD-MM-YYYY to match prd_start_dt display
    CONVERT(NVARCHAR(50), 
        DATEADD(DAY, -1,
            LEAD(TRY_CONVERT(DATE, prd_start_dt, 105)) 
            OVER (PARTITION BY prd_key ORDER BY TRY_CONVERT(DATE, prd_start_dt, 105))
        ), 105) AS prd_end_dt_trial,
    prd_end_dt
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509');

-----crm_sales_details-----

SELECT * FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

SELECT * FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

SELECT * FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

--invalid date format (Check for any Outliers)
SELECT 
NULLIF(sls_ship_dt ,0) AS sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 
OR LEN (sls_ship_dt) != 8 
OR sls_ship_dt >20500101 
OR sls_ship_dt < 19000101;

--Invalid Date orders
SELECT * FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt ;

-- Buisness rules, sales = Quantity * PRICE
-- values must not be NULL or -VE num

SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
          THEN sls_quantity * ABS(sls_price)
     ELSE sls_sales
END AS sls_sales,

CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
     ELSE sls_price
END AS sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_price <= 0 OR sls_quantity <= 0 OR sls_price <= 0


---- silver.erp_cust_az12-----
SELECT * FROM bronze.erp_cust_az12 

--Invalid Out of Range bdy date
SELECT DISTINCT TRY_CONVERT(DATE, bdate, 105) AS bdate
FROM bronze.erp_cust_az12
WHERE TRY_CONVERT(DATE, bdate, 105) < '01-01-1926' OR TRY_CONVERT(DATE, bdate, 105) > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT gen FROM silver.erp_cust_az12;