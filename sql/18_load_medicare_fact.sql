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
-- Populate the final deduplicated Medicare grain; missing joins cause rollback.
IF EXISTS (SELECT 1 FROM dw.FactMedicareService)
    THROW 50100, 'Expected empty target dw.FactMedicareService; this script is for a fresh build.', 1;
IF NOT EXISTS (SELECT 1 FROM stg.vwMedicare_Deduplicated)
    THROW 50101, 'Source stg.vwMedicare_Deduplicated is empty.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
INSERT INTO dw.FactMedicareService
(
    FinancialYearKey,
    GeographyKey,
    DemographicKey,
    ServiceKey,
    MedicareMeasureKey,
    DataStatusKey,
    MeasureValue,
    SourceMedicareCleanID,
    SourceWorksheet,
    SourceFileName
)
SELECT
    S.FinancialYearStart,
    G.GeographyKey,
    D.DemographicKey,
    SV.ServiceKey,
    M.MedicareMeasureKey,

    CASE S.DataStatus
        WHEN N'Published'
            THEN 1
        WHEN N'Not applicable'
            THEN 3
        WHEN N'Not provided'
            THEN 6
        WHEN N'Partial-year data'
            THEN 7
        WHEN N'Population proportion capped'
            THEN 8
    END,

    S.MeasureValue,
    S.MedicareCleanID,
    S.SourceWorksheet,
    S.SourceFileName

FROM stg.vwMedicare_Deduplicated AS S

INNER JOIN dw.DimGeography AS G
    ON  G.GeographicUnit = S.GeographicUnit
    AND G.GeographicCode = S.GeographicCode

INNER JOIN dw.DimFinancialYear AS FY
    ON FY.FinancialYearKey = S.FinancialYearStart

INNER JOIN dw.DimDemographic AS D
    ON D.DemographicGroup = S.DemographicGroup

INNER JOIN dw.DimService AS SV
    ON  SV.ServiceLevel = S.ServiceLevel
    AND SV.Service = S.Service

INNER JOIN dw.DimMedicareMeasure AS M
    ON M.MeasureName = S.MeasureName;
IF (SELECT COUNT_BIG(*) FROM dw.FactMedicareService) <> (SELECT COUNT_BIG(*) FROM stg.vwMedicare_Deduplicated)
    THROW 50102, 'Row reconciliation failed for dw.FactMedicareService; review missing dimension keys.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
