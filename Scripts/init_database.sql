/*
=============================================================
Script:  00_init_database.sql
Author:  Antony Alvin Johnson
=============================================================
Purpose:
    Initialises the DataWarehouse database and creates three
    schemas to support the Medallion Architecture:

        Bronze  - Raw data landing zone (source data as-is)
        Silver  - Cleaned and standardised data
        Gold    - Business-ready star schema for analytics

Warning:
    This script will DROP and recreate the DataWarehouse
    database if it already exists. All existing data will
    be permanently lost. Run only during initial setup.
=============================================================
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
