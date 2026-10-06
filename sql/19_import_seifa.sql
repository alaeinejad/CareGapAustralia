-- SQL Server 2022; UTF-8. Run via 10_run_etl.sql in SQLCMD mode.
USE [$(DatabaseName)];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
-- Reconstructed from project SQL history and aligned with the exported schema.
-- Static checks only; execution on SQL Server with source files remains unverified.
-- Inputs are project-prepared SA3 CSVs, not the original ABS Excel workbook.
IF EXISTS (SELECT 1 FROM stg.SEIFA_Distribution_Raw)
    THROW 50100, 'Expected empty target stg.SEIFA_Distribution_Raw; this script is for a fresh build.', 1;
IF EXISTS (SELECT 1 FROM stg.SEIFA_IRSD_Summary_Raw)
    THROW 50100, 'Expected empty target stg.SEIFA_IRSD_Summary_Raw; this script is for a fresh build.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
BULK INSERT stg.SEIFA_Distribution_Raw
FROM '$(SourceRoot)\ABS_SEIFA\seifa_sa3_2021_distribution.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001',
      ROWTERMINATOR='0x0a', TABLOCK);

BULK INSERT stg.SEIFA_IRSD_Summary_Raw
FROM '$(SourceRoot)\ABS_SEIFA\seifa_sa3_2021_irsd_summary.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001',
      ROWTERMINATOR='0x0a', TABLOCK);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
