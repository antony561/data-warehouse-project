# Data Catalog

This document provides a detailed description of all tables and views across the Bronze, Silver, and Gold layers of the DataWarehouse. It is intended to support both technical teams and business stakeholders in understanding the data model.

---

## Table of Contents

- [Bronze Layer](#bronze-layer)
  - [bronze.crm_cust_info](#bronzecrm_cust_info)
  - [bronze.crm_prd_info](#bronzecrm_prd_info)
  - [bronze.crm_sales_details](#bronzecrm_sales_details)
  - [bronze.erp_cust_az12](#bronzeerp_cust_az12)
  - [bronze.erp_loc_a101](#bronzeerp_loc_a101)
  - [bronze.erp_px_cat_g1v2](#bronzeerp_px_cat_g1v2)
- [Silver Layer](#silver-layer)
  - [silver.crm_cust_info](#silvercrm_cust_info)
  - [silver.crm_prd_info](#silvercrm_prd_info)
  - [silver.crm_sales_details](#silvercrm_sales_details)
  - [silver.erp_cust_az12](#silvererp_cust_az12)
  - [silver.erp_loc_a101](#silvererp_loc_a101)
  - [silver.erp_px_cat_g1v2](#silvererp_px_cat_g1v2)
- [Gold Layer](#gold-layer)
  - [gold.dim_customers](#golddim_customers)
  - [gold.dim_products](#golddim_products)
  - [gold.fact_sales](#goldfact_sales)

---

## Bronze Layer

The Bronze layer stores raw data exactly as received from the source systems (CRM and ERP). No transformations are applied. All columns use permissive data types (NVARCHAR, INT) to accommodate inconsistencies in the source data.

---

### bronze.crm_cust_info

**Source:** CRM System  
**Description:** Raw customer information including personal details and account creation date.

| Column | Data Type | Description |
|---|---|---|
| `cst_id` | INT | Unique customer identifier. May contain duplicates or NULLs in raw data. |
| `cst_key` | NVARCHAR(50) | Natural customer key used for joining with ERP tables. |
| `cst_firstname` | NVARCHAR(50) | Customer first name. May contain leading/trailing spaces. |
| `cst_lastname` | NVARCHAR(50) | Customer last name. May contain leading/trailing spaces. |
| `cst_marital_status` | NVARCHAR(50) | Marital status code. Raw values: 'S' (Single), 'M' (Married). |
| `cst_gndr` | NVARCHAR(50) | Gender code. Raw values: 'M' (Male), 'F' (Female). |
| `cst_create_date` | NVARCHAR(50) | Date the customer record was created. Stored as string in source. |

---

### bronze.crm_prd_info

**Source:** CRM System  
**Description:** Raw product information including product line, cost, and effective date range (SCD Type 2).

| Column | Data Type | Description |
|---|---|---|
| `prd_id` | INT | Unique product identifier. |
| `prd_key` | NVARCHAR(50) | Natural product key. Encodes category ID and product number. |
| `prd_nm` | NVARCHAR(50) | Product name. May contain leading/trailing spaces. |
| `prd_cost` | INT | Product cost. May contain NULLs or negative values. |
| `prd_line` | NVARCHAR(50) | Product line code. Raw values: 'R', 'M', 'T', 'S'. |
| `prd_start_dt` | NVARCHAR(50) | Product record effective start date. Stored as string in source. |
| `prd_end_dt` | NVARCHAR(50) | Product record effective end date. Stored as string in source. |

---

### bronze.crm_sales_details

**Source:** CRM System  
**Description:** Raw sales transaction records including order, shipping, and due dates, quantity, price, and total sales amount.

| Column | Data Type | Description |
|---|---|---|
| `sls_ord_num` | NVARCHAR(50) | Sales order number. May contain leading/trailing spaces. |
| `sls_prd_key` | NVARCHAR(50) | Product key foreign key reference. |
| `sls_cust_id` | INT | Customer ID foreign key reference. |
| `sls_order_dt` | INT | Order date stored as integer in YYYYMMDD format. May contain invalid values (0, wrong length). |
| `sls_ship_dt` | INT | Ship date stored as integer in YYYYMMDD format. May contain invalid values. |
| `sls_due_dt` | INT | Due date stored as integer in YYYYMMDD format. May contain invalid values. |
| `sls_sales` | INT | Total sales amount. May be NULL, zero, or inconsistent with quantity × price. |
| `sls_quantity` | INT | Number of units sold. |
| `sls_price` | INT | Unit price. May be NULL or negative. |

---

### bronze.erp_cust_az12

**Source:** ERP System  
**Description:** Supplementary customer data including birthdate and gender from the ERP system.

| Column | Data Type | Description |
|---|---|---|
| `cid` | NVARCHAR(50) | Customer ID. May include 'NAS' prefix that needs to be stripped for joining. |
| `bdate` | NVARCHAR(50) | Customer birthdate. Stored as string. May contain future or out-of-range dates. |
| `gen` | NVARCHAR(50) | Gender. Raw values inconsistent: 'M', 'Male', 'F', 'Female'. |

---

### bronze.erp_loc_a101

**Source:** ERP System  
**Description:** Customer location data including country of residence.

| Column | Data Type | Description |
|---|---|---|
| `cid` | NVARCHAR(50) | Customer ID for joining with CRM customer data. |
| `cntry` | NVARCHAR(50) | Country code or name. Raw values inconsistent: 'US', 'USA', 'DE', 'AU'. |

---

### bronze.erp_px_cat_g1v2

**Source:** ERP System  
**Description:** Product category and subcategory reference data.

| Column | Data Type | Description |
|---|---|---|
| `id` | NVARCHAR(50) | Category ID. Used for joining with product data. |
| `cat` | NVARCHAR(50) | Product category name. May contain leading/trailing spaces. |
| `subcat` | NVARCHAR(50) | Product subcategory name. May contain leading/trailing spaces. |
| `maintenance` | NVARCHAR(50) | Maintenance flag or type. May contain leading/trailing spaces. |

---

## Silver Layer

The Silver layer contains cleaned, standardised, and normalised data. All tables include a `dwh_create_date` audit column that records when the record was loaded into the warehouse.

---

### silver.crm_cust_info

**Source:** bronze.crm_cust_info  
**Description:** Cleaned customer data. Duplicates removed, names trimmed, gender and marital status standardised, dates converted.

| Column | Data Type | Description |
|---|---|---|
| `cst_id` | INT | Unique customer identifier. Deduplicated — one row per customer. |
| `cst_key` | NVARCHAR(50) | Natural customer key used for ERP joins. |
| `cst_firstname` | NVARCHAR(50) | Customer first name. Whitespace trimmed. |
| `cst_lastname` | NVARCHAR(50) | Customer last name. Whitespace trimmed. |
| `cst_marital_status` | NVARCHAR(50) | Standardised marital status. Values: 'Single', 'Married', 'n/a'. |
| `cst_gndr` | NVARCHAR(50) | Standardised gender. Values: 'Male', 'Female', 'n/a'. |
| `cst_create_date` | DATE | Customer creation date. Converted from NVARCHAR to DATE. |
| `dwh_create_date` | DATETIME2 | Timestamp of when the record was loaded into the warehouse. |

---

### silver.crm_prd_info

**Source:** bronze.crm_prd_info  
**Description:** Cleaned product data. Category ID derived from product key, product line standardised, SCD Type 2 end dates calculated using LEAD().

| Column | Data Type | Description |
|---|---|---|
| `prd_id` | INT | Unique product identifier. |
| `cat_id` | NVARCHAR(50) | Category ID derived from the first 5 characters of prd_key. Used to join with erp_px_cat_g1v2. |
| `prd_key` | NVARCHAR(50) | Cleaned product key with category prefix removed. |
| `prd_nm` | NVARCHAR(50) | Product name. Whitespace trimmed. |
| `prd_cost` | INT | Product cost. NULLs replaced with 0. |
| `prd_line` | NVARCHAR(50) | Standardised product line. Values: 'Road', 'Mountain', 'Touring', 'Other Sales', 'n/a'. |
| `prd_start_dt` | DATE | Product record effective start date. Converted from NVARCHAR to DATE. |
| `prd_end_dt` | DATE | Product record effective end date. Derived using LEAD() for SCD Type 2 tracking. NULL indicates current record. |
| `dwh_create_date` | DATETIME2 | Timestamp of when the record was loaded into the warehouse. |

---

### silver.crm_sales_details

**Source:** bronze.crm_sales_details  
**Description:** Cleaned sales transactions. Integer dates converted to DATE, invalid sales/price values recalculated.

| Column | Data Type | Description |
|---|---|---|
| `sls_ord_num` | NVARCHAR(50) | Sales order number. Whitespace trimmed. |
| `sls_prd_key` | NVARCHAR(50) | Product key foreign key reference. |
| `sls_cust_id` | INT | Customer ID foreign key reference. |
| `sls_order_dt` | DATE | Order date. Converted from YYYYMMDD integer. Invalid values set to NULL. |
| `sls_ship_dt` | DATE | Ship date. Converted from YYYYMMDD integer. Invalid values set to NULL. |
| `sls_due_dt` | DATE | Due date. Converted from YYYYMMDD integer. Invalid values set to NULL. |
| `sls_sales` | INT | Total sales amount. Recalculated as quantity × ABS(price) where NULL, zero, or inconsistent. |
| `sls_quantity` | INT | Number of units sold. |
| `sls_price` | INT | Unit price. Recalculated from sales / quantity where NULL or zero. |
| `dwh_create_date` | DATETIME2 | Timestamp of when the record was loaded into the warehouse. |

---

### silver.erp_cust_az12

**Source:** bronze.erp_cust_az12  
**Description:** Cleaned ERP customer demographics. NAS prefix removed, future birthdates nulled, gender standardised.

| Column | Data Type | Description |
|---|---|---|
| `cid` | NVARCHAR(50) | Customer ID. NAS prefix stripped for consistent joining with CRM data. |
| `bdate` | DATE | Customer birthdate. Converted to DATE. Future dates set to NULL. |
| `gen` | NVARCHAR(50) | Standardised gender. Values: 'Male', 'Female', 'n/a'. |
| `dwh_create_date` | DATETIME2 | Timestamp of when the record was loaded into the warehouse. |

---

### silver.erp_loc_a101

**Source:** bronze.erp_loc_a101  
**Description:** Cleaned customer location data. Country codes standardised to full country names.

| Column | Data Type | Description |
|---|---|---|
| `cid` | NVARCHAR(50) | Customer ID for joining with CRM customer data. |
| `cntry` | NVARCHAR(50) | Standardised country name. Values: 'United States', 'Germany', 'Australia', 'n/a'. |
| `dwh_create_date` | DATETIME2 | Timestamp of when the record was loaded into the warehouse. |

---

### silver.erp_px_cat_g1v2

**Source:** bronze.erp_px_cat_g1v2  
**Description:** Cleaned product category reference data. Whitespace trimmed across all fields.

| Column | Data Type | Description |
|---|---|---|
| `id` | NVARCHAR(50) | Category ID. Used for joining with silver.crm_prd_info on cat_id. |
| `cat` | NVARCHAR(50) | Product category name. Whitespace trimmed. |
| `subcat` | NVARCHAR(50) | Product subcategory name. Whitespace trimmed. |
| `maintenance` | NVARCHAR(50) | Product maintenance classification. Whitespace trimmed. |
| `dwh_create_date` | DATETIME2 | Timestamp of when the record was loaded into the warehouse. |

---

## Gold Layer

The Gold layer contains business-ready views modelled as a star schema. These views are the primary interface for BI reporting, ad-hoc SQL queries, and analytics. No data is physically loaded — views read from the Silver layer at query time.

---

### gold.dim_customers

**Source:** silver.crm_cust_info, silver.erp_cust_az12, silver.erp_loc_a101  
**Description:** Unified customer dimension. CRM and ERP data joined on customer key. CRM is the master source for gender where available.

| Column | Data Type | Description |
|---|---|---|
| `customer_key` | INT | Surrogate key generated using ROW_NUMBER(). Used for joining with fact_sales. |
| `customer_id` | INT | Original CRM customer ID (cst_id). |
| `customer_number` | NVARCHAR(50) | Natural customer key (cst_key). |
| `first_name` | NVARCHAR(50) | Customer first name. |
| `last_name` | NVARCHAR(50) | Customer last name. |
| `country` | NVARCHAR(50) | Customer country from ERP location data. |
| `marital_status` | NVARCHAR(50) | Customer marital status. Values: 'Single', 'Married', 'n/a'. |
| `gender` | NVARCHAR(50) | Resolved gender. CRM value used where available; ERP value used as fallback. Values: 'Male', 'Female', 'n/a'. |
| `birthdate` | DATE | Customer birthdate from ERP system. |
| `create_date` | DATE | Date the customer record was originally created in CRM. |

---

### gold.dim_products

**Source:** silver.crm_prd_info, silver.erp_px_cat_g1v2  
**Description:** Current product dimension. Historical product records (where prd_end_dt IS NOT NULL) are excluded. Product and category data joined on cat_id.

| Column | Data Type | Description |
|---|---|---|
| `product_key` | INT | Surrogate key generated using ROW_NUMBER(). Used for joining with fact_sales. |
| `product_id` | INT | Original CRM product ID (prd_id). |
| `product_number` | NVARCHAR(50) | Natural product key (prd_key). |
| `product_name` | NVARCHAR(50) | Product name. |
| `category_id` | NVARCHAR(50) | Category ID derived from product key. |
| `category` | NVARCHAR(50) | Product category name from ERP. |
| `sub_category` | NVARCHAR(50) | Product subcategory name from ERP. |
| `maintenance` | NVARCHAR(50) | Product maintenance classification from ERP. |
| `cost` | INT | Product cost. |
| `product_line` | NVARCHAR(50) | Product line. Values: 'Road', 'Mountain', 'Touring', 'Other Sales', 'n/a'. |
| `start_date` | DATE | Date from which this product record is effective. |

---

### gold.fact_sales

**Source:** silver.crm_sales_details, gold.dim_products, gold.dim_customers  
**Description:** Sales fact table. Each row represents one line item in a sales order. Joined to dimension tables via surrogate keys.

| Column | Data Type | Description |
|---|---|---|
| `order_number` | NVARCHAR(50) | Sales order number. |
| `product_key` | INT | Foreign key referencing gold.dim_products. |
| `customer_key` | INT | Foreign key referencing gold.dim_customers. |
| `order_date` | DATE | Date the order was placed. |
| `ship_date` | DATE | Date the order was shipped. |
| `due_date` | DATE | Date the order was due. |
| `sales_amount` | INT | Total sales value for the line item. |
| `quantity` | INT | Number of units ordered. |
| `price` | INT | Unit price at time of sale. |
