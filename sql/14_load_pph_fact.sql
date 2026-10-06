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
-- Deduplication uses the current staging view; preserve publication status.
IF EXISTS (SELECT 1 FROM dw.FactPPH)
    THROW 50100, 'Expected empty target dw.FactPPH; this script is for a fresh build.', 1;
IF NOT EXISTS (SELECT 1 FROM stg.vwPPH_Deduplicated)
    THROW 50101, 'Source stg.vwPPH_Deduplicated is empty.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
INSERT INTO dw.FactPPH
(
    FinancialYearKey,
    GeographyKey,
    DemographicKey,
    ConditionKey,
    MeasureKey,
    DataStatusKey,
    MeasureValue,
    SourcePPHRowID,
    SourceWorksheet
)
SELECT
    S.FinancialYearStart,
    G.GeographyKey,
    D.DemographicKey,
    C.ConditionKey,
    M.MeasureKey,

    CASE
        WHEN S.Flag = N'n.p.'
            THEN 2
        WHEN S.Flag = N'..'
            THEN 3
        WHEN S.MeasureValue IS NULL
         AND S.FlagExplanation = N'Nil or rounded to zero'
            THEN 4
        WHEN S.MeasureValue IS NULL
            THEN 5
        ELSE 1
    END AS DataStatusKey,

    S.MeasureValue,
    S.PPHRowID,
    S.SourceWorksheet
FROM stg.vwPPH_Deduplicated AS S

INNER JOIN dw.DimGeography AS G
    ON  G.GeographicUnit = S.GeographicUnit
    AND G.GeographicCode = S.GeographicCode

INNER JOIN dw.DimDemographic AS D
    ON D.DemographicGroup = S.DemographicGroup

INNER JOIN dw.DimCondition AS C
    ON  C.PPHGroup = S.PPHGroup
    AND C.PPHCondition = S.PPHCondition

INNER JOIN dw.DimMeasure AS M
    ON M.MeasureName = S.MeasureName;
IF (SELECT COUNT_BIG(*) FROM dw.FactPPH) <> (SELECT COUNT_BIG(*) FROM stg.vwPPH_Deduplicated)
    THROW 50102, 'Row reconciliation failed for dw.FactPPH; review missing dimension keys.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
