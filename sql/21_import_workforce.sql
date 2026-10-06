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
-- Two-column project CSV: SA3CodeRaw,PractitionerCountRaw. Remove Total and blank trailing rows.
IF EXISTS (SELECT 1 FROM stg.WorkforceGP_NationalRaw)
    THROW 50100, 'Expected empty target stg.WorkforceGP_NationalRaw; this script is for a fresh build.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
BULK INSERT stg.WorkforceGP_NationalRaw
FROM '$(SourceRoot)\HWD\Workforce_GP_SA3_2024.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001',
      ROWTERMINATOR='0x0a', TABLOCK);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
