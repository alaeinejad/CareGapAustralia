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
-- Populate current dimensions including mandatory overlap interpretation fields.
IF EXISTS (SELECT 1 FROM dw.DimFinancialYear)
    THROW 50100, 'Expected empty target dw.DimFinancialYear; this script is for a fresh build.', 1;
IF EXISTS (SELECT 1 FROM dw.DimGeography)
    THROW 50100, 'Expected empty target dw.DimGeography; this script is for a fresh build.', 1;
IF EXISTS (SELECT 1 FROM dw.DimDemographic)
    THROW 50100, 'Expected empty target dw.DimDemographic; this script is for a fresh build.', 1;
IF EXISTS (SELECT 1 FROM dw.DimCondition)
    THROW 50100, 'Expected empty target dw.DimCondition; this script is for a fresh build.', 1;
IF EXISTS (SELECT 1 FROM dw.DimMeasure)
    THROW 50100, 'Expected empty target dw.DimMeasure; this script is for a fresh build.', 1;
IF EXISTS (SELECT 1 FROM dw.DimDataStatus)
    THROW 50100, 'Expected empty target dw.DimDataStatus; this script is for a fresh build.', 1;
IF NOT EXISTS (SELECT 1 FROM stg.vwPPH_Deduplicated)
    THROW 50101, 'Source stg.vwPPH_Deduplicated is empty.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
INSERT INTO dw.DimFinancialYear
(
    FinancialYearKey,
    FinancialYearLabel,
    StartDate,
    EndDate
)
SELECT DISTINCT
    FinancialYearStart,
    FinancialYear,
    DATEFROMPARTS(FinancialYearStart, 7, 1),
    DATEFROMPARTS(FinancialYearStart + 1, 6, 30)
FROM stg.vwPPH_Deduplicated;

INSERT INTO dw.DimGeography
(
    GeographicUnit,
    GeographicCode,
    GeographicAreaName,
    StateTerritory,
    GeographicGroup,
    IsNational,
    IsAggregateArea
)
SELECT DISTINCT
    GeographicUnit,
    GeographicCode,
    GeographicAreaName,
    StateTerritory,
    GeographicGroup,

    CASE
        WHEN GeographicUnit = N'NAT' THEN 1
        ELSE 0
    END,

    CASE
        WHEN GeographicUnit IN (N'NAT', N'RA', N'SEIFA')
          OR GeographicCode IN
             (
                 N'003MET',
                 N'003REG',
                 N'004-01',
                 N'004-02',
                 N'004-03',
                 N'004-04',
                 N'004-05',
                 N'004-06'
             )
            THEN 1
        ELSE 0
    END
FROM stg.vwPPH_Deduplicated;

INSERT INTO dw.DimDemographic
(
    DemographicGroup,
    DemographicType,
    SortOrder,
    CanSumAcrossGroups,
    InterpretationNote
)
SELECT DISTINCT
    DemographicGroup,

    CASE
        WHEN DemographicGroup = N'All persons'
            THEN N'All persons'
        WHEN DemographicGroup IN (N'Females', N'Males')
            THEN N'Sex'
        ELSE N'Age group'
    END,

    CASE DemographicGroup
        WHEN N'All persons' THEN 1
        WHEN N'Females'     THEN 2
        WHEN N'Males'       THEN 3
        WHEN N'0–64'        THEN 4
        WHEN N'65+'         THEN 5
        ELSE 99
    END,
    0,
    N'Demographic groups overlap; select mutually exclusive groups before aggregation.'
FROM stg.vwPPH_Deduplicated;

INSERT INTO dw.DimCondition
(
    PPHGroup,
    PPHCondition,
    IsTotalCondition,
    ConditionRole,
    CanSumAcrossConditions,
    InterpretationNote
)
SELECT DISTINCT
    PPHGroup,
    PPHCondition,

    CASE
        WHEN PPHCondition LIKE N'Total%'
            THEN 1
        ELSE 0
    END,
    CASE
            WHEN PPHCondition = N'Total PPH'
                THEN N'Overall PPH total'

            WHEN PPHCondition = N'Total separations'
                THEN N'Hospital comparator'

            WHEN PPHCondition =
                 N'Total acute and vaccine-preventable'
                THEN N'Combined PPH category'

            WHEN PPHCondition IN
            (
                N'Total acute',
                N'Total chronic',
                N'Total vaccine-preventable'
            )
                THEN N'PPH category total'

            ELSE N'Specific PPH condition'
        END,
    0,
    CASE
            WHEN PPHCondition = N'Total PPH'
                THEN N'Use this reported value for overall PPH; do not reconstruct it by summing conditions or categories.'

            WHEN PPHCondition = N'Total separations'
                THEN N'All hospital separations comparator; this is not a PPH category.'

            WHEN PPHCondition =
                 N'Total acute and vaccine-preventable'
                THEN N'Combined reported category; do not add it to acute or vaccine-preventable totals.'

            WHEN PPHCondition LIKE N'Total%'
                THEN N'Reported category total; categories may overlap and must not be summed to calculate Total PPH.'

            ELSE
                N'Specific conditions may overlap within a hospitalisation; do not sum conditions to reconstruct category totals.'
        END
FROM stg.vwPPH_Deduplicated;

INSERT INTO dw.DimMeasure
(
    MeasureName,
    UnitOfMeasure,
    PreferredFormat,
    AggregationRule
)
SELECT DISTINCT
    MeasureName,

    CASE MeasureName
        WHEN N'Average length of stay (days)'
            THEN N'Days'
        WHEN N'Estimated resident population'
            THEN N'People'
        WHEN N'Hospitalisations per 100,000 people (age-standardised)'
            THEN N'Per 100,000 people'
        WHEN N'Hospitalisations per 100,000 people (crude)'
            THEN N'Per 100,000 people'
        WHEN N'Number of hospitalisations'
            THEN N'Hospitalisations'
        WHEN N'Number of same-day hospitalisations'
            THEN N'Hospitalisations'
        WHEN N'Percentage of hospitalisations that are same-day (%)'
            THEN N'Percent'
        WHEN N'Total bed days'
            THEN N'Bed days'
        ELSE N'Unknown'
    END,

    CASE MeasureName
        WHEN N'Average length of stay (days)' THEN N'0.0'
        WHEN N'Percentage of hospitalisations that are same-day (%)'
            THEN N'0.0%'
        WHEN N'Hospitalisations per 100,000 people (age-standardised)'
            THEN N'0.0'
        WHEN N'Hospitalisations per 100,000 people (crude)'
            THEN N'0.0'
        ELSE N'#,##0'
    END,

    CASE
        WHEN MeasureName IN
        (
            N'Average length of stay (days)',
            N'Hospitalisations per 100,000 people (age-standardised)',
            N'Hospitalisations per 100,000 people (crude)',
            N'Percentage of hospitalisations that are same-day (%)'
        )
            THEN N'Do not sum; use the reported value for the selected context'

        WHEN MeasureName = N'Estimated resident population'
            THEN N'Do not sum across overlapping geographies or demographic groups'

        ELSE
            N'Sum only across mutually exclusive categories'
    END
FROM stg.vwPPH_Deduplicated;

INSERT INTO dw.DimDataStatus
(
    DataStatusKey,
    DataStatus,
    IsValueAvailable,
    StatusDescription
)
VALUES
(1, N'Published',              1, N'A numeric value was published'),
(2, N'Not published',          0, N'AIHW suppressed or did not publish the result'),
(3, N'Not applicable',         0, N'The measure is not applicable to this record'),
(4, N'Nil or rounded to zero', 0, N'The result is nil or was rounded to zero'),
(5, N'Other missing',          0, N'The value is missing for another reason');
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
