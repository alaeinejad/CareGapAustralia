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
-- Final national load: exactly 334 matched SA3s; exclude 99999.
-- Source selector was labelled ASGS 2023. Code matches alone do not establish boundary equivalence.
-- Replaces only the selected year/category inside a transaction; no seven-area pilot seed.
IF NOT EXISTS (SELECT 1 FROM dw.DimCalendarYear WHERE CalendarYearKey=2024)
BEGIN
INSERT INTO dw.DimCalendarYear
        (
            CalendarYearKey,
            CalendarYear,
            YearStartDate,
            YearEndDate,
            YearLabel
        )
        VALUES
        (
            2024,
            2024,
            DATEFROMPARTS(2024, 1, 1),
            DATEFROMPARTS(2024, 12, 31),
            N'2024'
        );
END;
IF NOT EXISTS (SELECT 1 FROM dw.DimWorkforceCategory WHERE Profession=N'Medical Practitioners' AND PrimarySpecialty=N'General practice' AND MeasureName=N'Number of Practitioners')
BEGIN
INSERT INTO dw.DimWorkforceCategory
        (
            Profession,
            PrimarySpecialty,
            MeasureName,
            UnitOfMeasure,
            AggregationRule
        )
        VALUES
        (
            N'Medical Practitioners',
            N'General practice',
            N'Number of Practitioners',
            N'Practitioner headcount',
            N'Use the reported value for the selected geography and year. '
            + N'Sum only across mutually exclusive geographies.'
        );
END;
GO
IF (SELECT COUNT_BIG(*) FROM stg.WorkforceGP_NationalRaw) <> 335
    THROW 50110, 'Expected 335 raw workforce rows including code 99999.', 1;
IF EXISTS (SELECT 1 FROM stg.WorkforceGP_NationalRaw
           WHERE TRY_CONVERT(int, REPLACE(REPLACE(PractitionerCountRaw,CHAR(13),''),CHAR(10),'')) IS NULL)
    THROW 50111, 'Invalid numeric workforce source row.', 1;
DECLARE @CalendarYearKey smallint;
DECLARE @WorkforceCategoryKey smallint;
DECLARE @LoadTime datetime2(6) = SYSDATETIME();

SELECT @CalendarYearKey = CalendarYearKey
FROM dw.DimCalendarYear
WHERE CalendarYear = 2024;

SELECT @WorkforceCategoryKey = WorkforceCategoryKey
FROM dw.DimWorkforceCategory
WHERE Profession = N'Medical Practitioners'
  AND PrimarySpecialty = N'General practice'
  AND MeasureName = N'Number of Practitioners';

IF @CalendarYearKey IS NULL
    THROW 50001, 'Calendar year 2024 was not found.', 1;

IF @WorkforceCategoryKey IS NULL
    THROW 50002, 'General practice workforce category was not found.', 1;

DROP TABLE IF EXISTS #WorkforceClean;

SELECT
    G.GeographyKey,
    C.SA3Code,
    G.GeographicAreaName,
    TRY_CONVERT
    (
        int,
        REPLACE(REPLACE(R.PractitionerCountRaw, CHAR(13), ''), CHAR(10), '')
    ) AS PractitionerCount
INTO #WorkforceClean
FROM stg.WorkforceGP_NationalRaw AS R
CROSS APPLY
(
    SELECT LTRIM(RTRIM(
        REPLACE(REPLACE(R.SA3CodeRaw, CHAR(13), ''), CHAR(10), '')
    )) AS SA3Code
) AS C
JOIN dw.DimGeography AS G
    ON G.GeographicCode = C.SA3Code
   AND G.GeographicUnit = N'SA3'
WHERE C.SA3Code <> N'99999'
  AND TRY_CONVERT
      (
          int,
          REPLACE(REPLACE(R.PractitionerCountRaw, CHAR(13), ''), CHAR(10), '')
      ) IS NOT NULL;

-- کنترل‌های قبل از تغییر Fact
IF (SELECT COUNT(*) FROM #WorkforceClean) <> 334
    THROW 50003, 'Expected 334 matched workforce rows.', 1;

IF EXISTS
(
    SELECT GeographyKey
    FROM #WorkforceClean
    GROUP BY GeographyKey
    HAVING COUNT(*) > 1
)
    THROW 50004, 'Duplicate GeographyKey detected in workforce source.', 1;

IF EXISTS
(
    SELECT 1
    FROM #WorkforceClean
    WHERE PractitionerCount < 0
)
    THROW 50005, 'Negative practitioner count detected.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM dw.FactWorkforce
    WHERE CalendarYearKey = @CalendarYearKey
      AND WorkforceCategoryKey = @WorkforceCategoryKey;

    INSERT INTO dw.FactWorkforce
    (
        CalendarYearKey,
        GeographyKey,
        WorkforceCategoryKey,
        PractitionerCount,
        GeographyStandard,
        SourceFileName,
        SourceLoadedAt,
        DWLoadedAt
    )
    SELECT
        @CalendarYearKey,
        GeographyKey,
        @WorkforceCategoryKey,
        PractitionerCount,
        N'ASGS 2023',
        N'Workforce_GP_SA3_2024.csv',
        @LoadTime,
        @LoadTime
    FROM #WorkforceClean;

    IF @@ROWCOUNT <> 334
        THROW 50006, 'Fact insert did not produce 334 rows.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO
