-- Schema-only installer. See 00_config.sql; creates an EMPTY database.
:on error exit
:r 00_config.sql
USE [master];
GO
IF DB_ID(N'$(DatabaseName)') IS NOT NULL
    THROW 50010, 'Target database already exists. Choose an unused DatabaseName.', 1;
GO
CREATE DATABASE [$(DatabaseName)];
GO
ALTER DATABASE [$(DatabaseName)] SET COMPATIBILITY_LEVEL = 160;
GO
:r 01_schemas.sql
:r 02_staging_tables.sql
:r 03_dimensions.sql
:r 04_fact_tables.sql
:r 05_indexes_constraints.sql
:r 06_staging_views.sql
:r 07_reporting_views.sql
:r 08_import_procedures.sql
:r 09_validation.sql
