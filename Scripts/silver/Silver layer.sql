-- crm_cust_info--
INSERT INTO silver.crm_cust_info (
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date
)

SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
     WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
     ELSE 'n/a'
END AS cst_marital_status,
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
     WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
     ELSE 'n/a'
END AS cst_gndr,
TRY_CONVERT(DATE, cst_create_date) AS cst_create_date
FROM (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rank
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
)t 
WHERE rank = 1;

-----crm_prd_info-----

INSERT INTO silver.crm_prd_info (
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
)

SELECT
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
TRIM(prd_nm) AS prd_nm,
ISNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
     WHEN 'R' THEN 'Road'
     WHEN 'M' THEN 'Mountain'
     WHEN 'T' THEN 'Touring'
     WHEN 'S' THEN 'Other sales'
     ELSE 'n/a'
END AS prd_line,
TRY_CONVERT(DATE, prd_start_dt, 105) AS prd_start_dt,
DATEADD(DAY, -1,
    LEAD(TRY_CONVERT(DATE, prd_start_dt, 105)) 
    OVER (PARTITION BY prd_key ORDER BY TRY_CONVERT(DATE, prd_start_dt, 105))
) AS prd_end_dt
FROM bronze.crm_prd_info;

-- crm.sales_details

INSERT INTO silver.crm_sales_details(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)

SELECT
TRIM(sls_ord_num) AS sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0  OR LEN(sls_order_dt) != 8 THEN NULL
     ELSE CAST(CAST (sls_order_dt AS VARCHAR) AS DATE)
END AS sls_order_dt,
CASE WHEN sls_ship_dt = 0  OR LEN(sls_ship_dt) != 8 THEN NULL
     ELSE CAST(CAST (sls_ship_dt AS VARCHAR) AS DATE)
END AS sls_ship_dt,
CASE WHEN sls_due_dt = 0  OR LEN(sls_due_dt) != 8 THEN NULL
     ELSE CAST(CAST (sls_due_dt AS VARCHAR) AS DATE)
END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
          THEN sls_quantity * ABS(sls_price)
     ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
     ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;

---- silver.erp_cust_az12----- 
INSERT INTO silver.erp_cust_az12(
cid,
bdate,
gen
)

SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
     ELSE cid
END AS cid,
CASE WHEN TRY_CONVERT(DATE, bdate, 105) > GETDATE() THEN NULL
     ELSE TRY_CONVERT(DATE, bdate, 105)
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('M','Male') THEN 'Male'
     WHEN UPPER(TRIM(gen)) IN ('F','Female') THEN 'Female'
     ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12;