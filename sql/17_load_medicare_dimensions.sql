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
-- Extend shared years and demographics; populate service and measure dimensions.
IF EXISTS (SELECT 1 FROM dw.DimService)
    THROW 50100, 'Expected empty target dw.DimService; this script is for a fresh build.', 1;
IF EXISTS (SELECT 1 FROM dw.DimMedicareMeasure)
    THROW 50100, 'Expected empty target dw.DimMedicareMeasure; this script is for a fresh build.', 1;
IF NOT EXISTS (SELECT 1 FROM stg.vwMedicare_Deduplicated)
    THROW 50101, 'Source stg.vwMedicare_Deduplicated is empty.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
INSERT INTO dw.DimFinancialYear (FinancialYearKey, FinancialYearLabel, StartDate, EndDate)
SELECT DISTINCT s.FinancialYearStart,s.FinancialYear,
       DATEFROMPARTS(s.FinancialYearStart,7,1),DATEFROMPARTS(s.FinancialYearStart+1,6,30)
FROM stg.vwMedicare_Deduplicated s
WHERE NOT EXISTS (SELECT 1 FROM dw.DimFinancialYear y WHERE y.FinancialYearKey=s.FinancialYearStart);

INSERT INTO dw.DimDemographic
(
    DemographicGroup,
    DemographicType,
    SortOrder,
    CanSumAcrossGroups,
    InterpretationNote
)
SELECT DISTINCT
    M.DemographicGroup,

    CASE
        WHEN M.DemographicGroup = N'All persons'
            THEN N'All persons'
        WHEN M.DemographicGroup IN (N'Females', N'Males')
            THEN N'Sex'
        ELSE N'Age group'
    END,

    CASE M.DemographicGroup
        WHEN N'All persons' THEN 1
        WHEN N'Females'     THEN 2
        WHEN N'Males'       THEN 3
        WHEN N'0-14'        THEN 10
        WHEN N'15-24'       THEN 11
        WHEN N'25-44'       THEN 12
        WHEN N'45-64'       THEN 13
        WHEN N'65-79'       THEN 14
        WHEN N'80+'         THEN 15
        WHEN N'0-24'        THEN 20
        WHEN N'65+'         THEN 21
        ELSE 99
    END,

    0,

    N'Demographic groups include overlapping totals, sex and age classifications; do not sum across groups without selecting a mutually exclusive set.'

FROM
(
    SELECT DISTINCT DemographicGroup
    FROM stg.vwMedicare_Deduplicated
) AS M

WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.DimDemographic AS D
    WHERE D.DemographicGroup = M.DemographicGroup
);

INSERT INTO dw.DimService
(
    ServiceLevel,
    ServiceLevelNumber,
    Service,
    CanSumAcrossServices,
    InterpretationNote
)
SELECT DISTINCT
    ServiceLevel,
    TRY_CONVERT
    (
        TINYINT,
        REPLACE(ServiceLevel, N'Level ', N'')
    ),
    Service,
    0,
    N'Service levels are hierarchical and may overlap; select one service level and do not sum parent and child services together.'
FROM stg.vwMedicare_Deduplicated;

INSERT INTO dw.DimMedicareMeasure
(
    MeasureName,
    UnitOfMeasure,
    ScaleDivisor,
    PreferredFormat,
    AggregationRule
)
SELECT DISTINCT
    MeasureName,

    CASE
        WHEN MeasureName =
             N'Percentage of people who had the service (%)'
            THEN N'Percent'
        WHEN MeasureName LIKE N'%benefits%'
          OR MeasureName = N'Total provider fees ($)'
            THEN N'AUD'
        WHEN MeasureName LIKE N'%per 100 people%'
            THEN N'Per 100 people'
        WHEN MeasureName = N'Estimated resident population'
            THEN N'People'
        WHEN MeasureName LIKE N'No.%'
            THEN N'Count'
        ELSE N'Rate'
    END,

    CASE
        WHEN MeasureName =
             N'Percentage of people who had the service (%)'
            THEN 100.00
        ELSE 1.00
    END,

    CASE
        WHEN MeasureName =
             N'Percentage of people who had the service (%)'
            THEN N'0.00%'
        WHEN MeasureName LIKE N'%benefits%'
          OR MeasureName = N'Total provider fees ($)'
            THEN N'$#,##0'
        WHEN MeasureName IN
        (
            N'No. services',
            N'No. patients',
            N'No. of GP residential aged care attendances',
            N'No. of GP residential aged care patients',
            N'Estimated resident population'
        )
            THEN N'#,##0'
        ELSE N'0.00'
    END,

    CASE
        WHEN MeasureName IN
        (
            N'No. services',
            N'No. patients',
            N'Total Medicare benefits paid ($)',
            N'Total provider fees ($)',
            N'No. of GP residential aged care attendances',
            N'No. of GP residential aged care patients'
        )
            THEN N'Sum only across mutually exclusive geographies, demographic groups and services.'

        ELSE
            N'Do not sum; use the reported value for the selected geography, demographic group, service and year.'
    END

FROM stg.vwMedicare_Deduplicated;

IF NOT EXISTS (SELECT 1 FROM dw.DimDataStatus WHERE DataStatusKey=6)
BEGIN
INSERT INTO dw.DimDataStatus
    (
        DataStatusKey,
        DataStatus,
        IsValueAvailable,
        StatusDescription
    )
    VALUES
    (
        6,
        N'Not provided',
        0,
        N'AIHW did not provide a numeric result.'
    );
END;

IF NOT EXISTS (SELECT 1 FROM dw.DimDataStatus WHERE DataStatusKey=7)
BEGIN
INSERT INTO dw.DimDataStatus
    (
        DataStatusKey,
        DataStatus,
        IsValueAvailable,
        StatusDescription
    )
    VALUES
    (
        7,
        N'Partial-year data',
        1,
        N'The service was available for only part of the financial year; interpret with caution.'
    );
END;

IF NOT EXISTS (SELECT 1 FROM dw.DimDataStatus WHERE DataStatusKey=8)
BEGIN
INSERT INTO dw.DimDataStatus
    (
        DataStatusKey,
        DataStatus,
        IsValueAvailable,
        StatusDescription
    )
    VALUES
    (
        8,
        N'Population proportion capped',
        1,
        N'Medicare patient count exceeded estimated resident population; the reported proportion was capped at 100%.'
    );
END;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
