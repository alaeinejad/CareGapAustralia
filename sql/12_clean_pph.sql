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
-- Trim source text, repair documented SEIFA endpoint codes, preserve raw codes.
IF EXISTS (SELECT 1 FROM stg.PPH_Clean)
    THROW 50100, 'Expected empty target stg.PPH_Clean; this script is for a fresh build.', 1;
IF NOT EXISTS (SELECT 1 FROM stg.PPH_Raw)
    THROW 50101, 'Source stg.PPH_Raw is empty.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
INSERT INTO stg.PPH_Clean
(
    SourceCode,
    DataSource,
    ReleaseName,
    SourceWorksheet,
    FinancialYear,
    FinancialYearStart,
    StateTerritory,
    GeographicUnit,
    RawGeographicCode,
    GeographicCode,
    GeographicAreaName,
    GeographicGroup,
    DemographicGroup,
    PPHGroup,
    PPHCondition,
    MeasureName,
    MeasureValue,
    Flag,
    FlagExplanation,
    IsPublished
)
SELECT
    LTRIM(RTRIM(Code)),
    LTRIM(RTRIM(DataSource)),
    LTRIM(RTRIM(Name)),
    LTRIM(RTRIM(Worksheet)),

    LTRIM(RTRIM([Year])),
    TRY_CONVERT(SMALLINT, LEFT(LTRIM(RTRIM([Year])), 4)),

    NULLIF(LTRIM(RTRIM(StateTerritory)), N''),
    LTRIM(RTRIM(GeographicUnit)),
    NULLIF(LTRIM(RTRIM(GeographicCode)), N''),

    CASE
        WHEN GeographicUnit = N'SEIFA'
         AND GeographicAreaName = N'Quintile 1–Lowest'
            THEN N'006-01'
        WHEN GeographicUnit = N'SEIFA'
         AND GeographicAreaName = N'Quintile 5–Highest'
            THEN N'006-05'
        ELSE LTRIM(RTRIM(GeographicCode))
    END,

    LTRIM(RTRIM(GeographicAreaName)),
    NULLIF(LTRIM(RTRIM(GeographicGroup)), N''),
    LTRIM(RTRIM(DemographicGroup)),
    LTRIM(RTRIM(PPHGroup)),
    LTRIM(RTRIM(PPHCondition)),
    LTRIM(RTRIM(MeasureName)),

    TRY_CONVERT(
        DECIMAL(19,4),
        NULLIF(LTRIM(RTRIM(MeasureValue)), N'')
    ),

    NULLIF(LTRIM(RTRIM(Flag)), N''),

    NULLIF(
        LTRIM(RTRIM(REPLACE(FlagExplanation, NCHAR(13), N''))),
        N''
    ),

    CASE
        WHEN LTRIM(RTRIM(Flag)) = N'n.p.' THEN 0
        WHEN LTRIM(RTRIM(Flag)) = N'..'   THEN 0
        WHEN TRY_CONVERT(DECIMAL(19,4), NULLIF(LTRIM(RTRIM(MeasureValue)), N'')) IS NULL THEN 0
        ELSE 1
    END
FROM stg.PPH_Raw;
IF (SELECT COUNT_BIG(*) FROM stg.PPH_Clean) <> (SELECT COUNT_BIG(*) FROM stg.PPH_Raw)
    THROW 50102, 'Row reconciliation failed for stg.PPH_Clean; review missing dimension keys.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
