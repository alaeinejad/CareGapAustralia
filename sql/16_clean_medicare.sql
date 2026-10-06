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
-- Retain raw values and audit fields; remove currency, percent and grouping symbols.
IF EXISTS (SELECT 1 FROM stg.Medicare_Clean)
    THROW 50100, 'Expected empty target stg.Medicare_Clean; this script is for a fresh build.', 1;
IF NOT EXISTS (SELECT 1 FROM stg.Medicare_Raw)
    THROW 50101, 'Source stg.Medicare_Raw is empty.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
INSERT INTO stg.Medicare_Clean
(
    SourceCode,
    DataSource,
    ReleaseName,
    SourceWorksheet,
    FinancialYear,
    FinancialYearStart,
    StateTerritory,
    RawGeographicUnit,
    GeographicUnit,
    GeographicCode,
    GeographicAreaName,
    GeographicGroup,
    ServiceLevel,
    Service,
    MeasureName,
    DemographicGroup,
    RawMeasureValue,
    MeasureValue,
    Flag,
    FlagExplanation,
    DataStatus,
    IsValueAvailable,
    IsCautionFlag,
    SourceFileName,
    LoadBatchID,
    LoadedAt
)
SELECT
    LTRIM(RTRIM(Code)),
    LTRIM(RTRIM(DataSource)),
    LTRIM(RTRIM(Name)),
    LTRIM(RTRIM(Worksheet)),

    LEFT(LTRIM(RTRIM([Year])), 4)
        + N'–'
        + RIGHT(LTRIM(RTRIM([Year])), 2),

    TRY_CONVERT(SMALLINT, LEFT(LTRIM(RTRIM([Year])), 4)),

    NULLIF(LTRIM(RTRIM(StateTerritory)), N''),
    NULLIF(LTRIM(RTRIM(GeographicUnit)), N''),

    CASE
        WHEN GeographicUnit = N'National'
            THEN N'NAT'
        WHEN GeographicCode IN (N'003MET', N'003REG')
            THEN N'PHN'
        WHEN GeographicCode LIKE N'004-%'
            THEN N'SA3'
        ELSE LTRIM(RTRIM(GeographicUnit))
    END,

    LTRIM(RTRIM(GeographicCode)),
    LTRIM(RTRIM(GeographicAreaName)),
    NULLIF(LTRIM(RTRIM(GeographicGroup)), N''),

    LTRIM(RTRIM(ServiceLevel)),
    LTRIM(RTRIM(Service)),
    LTRIM(RTRIM(MeasureName)),
    LTRIM(RTRIM(DemographicGroup)),

    NULLIF(LTRIM(RTRIM(MeasureValue)), N''),

    TRY_CONVERT
    (
        DECIMAL(28,6),
        TRY_CONVERT
        (
            FLOAT,
            NULLIF
            (
                LTRIM
                (
                    RTRIM
                    (
                        REPLACE
                        (
                            REPLACE
                            (
                                REPLACE(MeasureValue, N'$', N''),
                                N'%',
                                N''
                            ),
                            N',',
                            N''
                        )
                    )
                ),
                N''
            )
        )
    ),

    NULLIF(LTRIM(RTRIM(Flag)), N''),

    NULLIF
    (
        LTRIM
        (
            RTRIM
            (
                REPLACE(FlagExplanation, NCHAR(13), N'')
            )
        ),
        N''
    ),

    CASE
        WHEN LTRIM(RTRIM(Flag)) = N'n.p.'
            THEN N'Not provided'
        WHEN LTRIM(RTRIM(Flag)) = N'n.a.'
            THEN N'Not applicable'
        WHEN LTRIM(RTRIM(Flag)) = N'*'
            THEN N'Partial-year data'
        WHEN LTRIM(RTRIM(Flag)) = N'#'
            THEN N'Population proportion capped'
        WHEN NULLIF(LTRIM(RTRIM(MeasureValue)), N'') IS NULL
            THEN N'Other missing'
        ELSE N'Published'
    END,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(MeasureValue)), N'') IS NULL
            THEN 0
        ELSE 1
    END,

    CASE
        WHEN LTRIM(RTRIM(Flag)) IN (N'*', N'#')
            THEN 1
        ELSE 0
    END,

    SourceFileName,
    LoadBatchID,
    LoadedAt

FROM stg.Medicare_Raw;
IF (SELECT COUNT_BIG(*) FROM stg.Medicare_Clean) <> (SELECT COUNT_BIG(*) FROM stg.Medicare_Raw)
    THROW 50102, 'Row reconciliation failed for stg.Medicare_Clean; review missing dimension keys.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
