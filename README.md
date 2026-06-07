# Data Warehouse Project

![SQL Server](https://img.shields.io/badge/SQL-SQL%20Server-4479A1?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Azure Data Studio](https://img.shields.io/badge/Azure%20Data%20Studio-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge)

An end-to-end Data Warehouse built from scratch using SQL Server, implementing the Medallion Architecture (Bronze, Silver, Gold) to transform raw CRM and ERP data into business-ready analytics views.

---

## High Level Architecture

<img width="1220" height="617" alt="post1" src="https://github.com/user-attachments/assets/4c0c8d58-e411-4196-b7e2-beabf4575b68" />

The warehouse follows a three-layer Medallion Architecture:

| Layer | Purpose | Object Type |
|---|---|---|
| **Bronze** | Raw data landing zone — exact copy of source, no transformations | Tables |
| **Silver** | Cleaned and standardised data — duplicates removed, types fixed, values normalised | Tables |
| **Gold** | Business-ready data modelled as a star schema for analytics and reporting | Views |

---

## Data Flow

<img width="1092" height="675" alt="post3" src="https://github.com/user-attachments/assets/b3c32605-eacc-4255-a9c9-f44d6de6aadc" />

Six source tables from two systems (CRM and ERP) flow through the pipeline and consolidate into three Gold layer objects:

- `fact_sales` — all sales transactions
- `dim_customers` — unified customer dimension
- `dim_products` — unified product dimension

---

## Integration Model

<img width="1277" height="667" alt="post2" src="https://github.com/user-attachments/assets/54f14cd1-d2df-4127-bb05-86406a16f3ec" />

---

## Data Sources

**CRM System:**

| Table | Description |
|---|---|
| `crm_sales_details` | Sales and order transaction records |
| `crm_cust_info` | Core customer information |
| `crm_prd_info` | Current and historical product data (SCD Type 2) |

**ERP System:**

| Table | Description |
|---|---|
| `erp_cust_az12` | Extra customer data including birthdate |
| `erp_loc_a101` | Customer location and country |
| `erp_px_cat_g1v2` | Product categories |

---

## Repository Structure

```
data-warehouse-project/
   datasets/
      source_crm/          — CRM source CSV files
      source_erp/          — ERP source CSV files
   docs/
      data_architecture.png
      data_flow.png
      integration_model.png
   scripts/
      init_database.sql    — Creates DataWarehouse database and schemas
      bronze/
         ddl_bronze.sql    — Creates bronze layer tables
         load_bronze.sql   — Stored procedure: loads raw data into bronze
      silver/
         ddl_silver.sql    — Creates silver layer tables
         load_silver.sql   — Stored procedure: cleans and loads silver layer
      gold/
         ddl_gold.sql      — Creates gold layer views (star schema)
   tests/
      quality_checks_silver.sql  — Data quality checks for bronze and silver
      quality_checks_gold.sql    — Data quality checks for gold layer
   README.md
```

---

## How to Run

**Prerequisites:**
- SQL Server Express (free)
- Azure Data Studio or SSMS

**Steps:**

1. Clone the repository
2. Open Azure Data Studio and connect to your SQL Server instance
3. Update the file paths in `load_bronze.sql` to match your local environment
4. Run scripts in order:

```sql
-- Step 1: Create database and schemas
-- Run: scripts/init_database.sql

-- Step 2: Create bronze tables
-- Run: scripts/bronze/ddl_bronze.sql

-- Step 3: Load raw data into bronze
EXEC bronze.load_bronze;

-- Step 4: Create silver tables
-- Run: scripts/silver/ddl_silver.sql

-- Step 5: Clean and load silver layer
EXEC silver.load_silver;

-- Step 6: Create gold views
-- Run: scripts/gold/ddl_gold.sql
```

---

## Silver Layer Transformations

| Issue Found in Bronze | Fix Applied in Silver |
|---|---|
| Duplicate customer records | `ROW_NUMBER()` — keep most recent record per customer |
| NULL primary keys | Filtered out in subquery |
| Inconsistent gender values (M/F) | Standardised to Male/Female using `CASE WHEN` |
| Inconsistent marital status (S/M) | Standardised to Single/Married |
| Unwanted spaces in name fields | `TRIM()` applied |
| Dates stored as NVARCHAR | `TRY_CONVERT(DATE, ..., 105)` |
| Invalid date orders (end before start) | `LEAD()` used to derive correct end dates (SCD Type 2) |
| NULL or negative sales amounts | Recalculated as `quantity × ABS(price)` |
| Inconsistent country codes (US/USA) | Standardised to full country name |
| Future birthdates | Set to NULL |
| NAS prefix in ERP customer IDs | Prefix stripped using `SUBSTRING()` |

---

## Key Concepts Demonstrated

- **Medallion Architecture** — Bronze, Silver, Gold layered data design
- **ETL Pipelines** — Full load with Truncate and Insert using Stored Procedures
- **Data Quality Checks** — Duplicate detection, null handling, format validation
- **SCD Type 2** — Slowly Changing Dimensions for historical product tracking
- **Star Schema Design** — Fact and dimension table modelling in Gold layer
- **Data Integration** — Joining CRM and ERP sources with business logic (CRM as master for gender)
- **Error Handling** — `BEGIN TRY / BEGIN CATCH` in stored procedures
- **Performance Monitoring** — Load duration tracking per table and per batch

---

## Tools Used

- SQL Server Express 2022
- Azure Data Studio
- Draw.io (diagrams.net)

---

*Author: Antony Alvin Johnson*  
*GitHub: [github.com/antony561](https://github.com/antony561)*  
*LinkedIn: [linkedin.com/in/antony-alvin-johnson](https://linkedin.com/in/antony-alvin-johnson)*
