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
-- Original AIHW PPH CSV, 2017-18 to 2023-24, Windows-1252.
IF EXISTS (SELECT 1 FROM stg.PPH_Raw)
    THROW 50100, 'Expected empty target stg.PPH_Raw; this script is for a fresh build.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
BULK INSERT stg.PPH_Raw
FROM '$(SourceRoot)\AIHW_PPH\aihw-hpf-76-csv-file-2017-18-to-2023-24.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='1252',
      ROWTERMINATOR='0x0a', TABLOCK);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
