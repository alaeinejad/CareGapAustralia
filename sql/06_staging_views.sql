-- SQL Server 2022. UTF-8. Run through 00_install.sql in SQLCMD mode.
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
GO
CREATE   VIEW [stg].[vwSEIFA_Distribution_Clean]
AS
SELECT
    TRY_CONVERT
    (
        smallint,
        NULLIF(TRIM(SEIFAReferenceYear), N'')
    ) AS SEIFAReferenceYear,

    TRIM(GeographicUnit) AS GeographicUnit,
    TRIM(SA3Code) AS SA3Code,
    TRIM(SA3Name) AS SA3Name,
    TRIM(SEIFAIndex) AS SEIFAIndex,

    TRY_CONVERT
    (
        tinyint,
        NULLIF(TRIM(ScoreCategoryNumber), N'')
    ) AS ScoreCategoryNumber,

    TRIM(ScoreCategoryLabel) AS ScoreCategoryLabel,

    TRY_CONVERT
    (
        smallint,
        NULLIF(TRIM(ScoreLowerBound), N'')
    ) AS ScoreLowerBound,

    TRY_CONVERT
    (
        smallint,
        NULLIF(TRIM(ScoreUpperBound), N'')
    ) AS ScoreUpperBound,

    TRY_CONVERT
    (
        bit,
        NULLIF(TRIM(IsExcludedSA1Population), N'')
    ) AS IsExcludedSA1Population,

    TRY_CONVERT
    (
        int,
        NULLIF(TRIM(PopulationCount), N'')
    ) AS PopulationCount,

    TRIM(REPLACE(SourceColumn, CHAR(13), N'')) AS SourceColumn

FROM stg.SEIFA_Distribution_Raw;
GO

CREATE   VIEW [stg].[vwSEIFA_IRSD_Summary_Clean]
AS
SELECT
    TRY_CONVERT
    (
        smallint,
        NULLIF(TRIM(SEIFAReferenceYear), N'')
    ) AS SEIFAReferenceYear,

    TRIM(GeographicUnit) AS GeographicUnit,
    TRIM(SA3Code) AS SA3Code,
    TRIM(SA3Name) AS SA3Name,

    TRY_CONVERT(int, NULLIF(TRIM(IRSDPopulationTotal), N''))
        AS IRSDPopulationTotal,

    TRY_CONVERT(int, NULLIF(TRIM(IRSDPopulationIncluded), N''))
        AS IRSDPopulationIncluded,

    TRY_CONVERT(int, NULLIF(TRIM(IRSDPopulationExcluded), N''))
        AS IRSDPopulationExcluded,

    TRY_CONVERT(bit, NULLIF(TRIM(IsIRSDDistributionAvailable), N''))
        AS IsIRSDDistributionAvailable,

    TRY_CONVERT(int, NULLIF(TRIM(IRSDLowestDecilePopulation), N''))
        AS IRSDLowestDecilePopulation,

    TRY_CONVERT(int, NULLIF(TRIM(IRSDMiddleDecilesPopulation), N''))
        AS IRSDMiddleDecilesPopulation,

    TRY_CONVERT(int, NULLIF(TRIM(IRSDHighestDecilePopulation), N''))
        AS IRSDHighestDecilePopulation,

    TRY_CONVERT
    (
        decimal(18,8),
        NULLIF(TRIM(IRSDLowestDecileShareTotalPopulation), N'')
    ) AS IRSDLowestDecileShareTotalPopulation,

    TRY_CONVERT
    (
        decimal(18,8),
        NULLIF(TRIM(IRSDLowestDecileShareIncludedPopulation), N'')
    ) AS IRSDLowestDecileShareIncludedPopulation,

    TRY_CONVERT
    (
        decimal(18,8),
        NULLIF(TRIM(IRSDHighestDecileShareTotalPopulation), N'')
    ) AS IRSDHighestDecileShareTotalPopulation,

    TRY_CONVERT
    (
        decimal(18,8),
        NULLIF(TRIM(IRSDExcludedPopulationShare), N'')
    ) AS IRSDExcludedPopulationShare,

    TRIM(REPLACE(SourceFileName, CHAR(13), N'')) AS SourceFileName

FROM stg.SEIFA_IRSD_Summary_Raw;
GO

CREATE   VIEW [stg].[vwPPH_Deduplicated]
AS
WITH RankedRows AS
(
    SELECT
        PPHRowID,
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
        IsPublished,

        ROW_NUMBER() OVER
        (
            PARTITION BY
                FinancialYearStart,
                GeographicUnit,
                GeographicCode,
                DemographicGroup,
                PPHGroup,
                PPHCondition,
                MeasureName
            ORDER BY
                CASE SourceWorksheet
                    WHEN N'Table1' THEN 1
                    WHEN N'Table2' THEN 2
                    WHEN N'Table3' THEN 3
                    WHEN N'Table4' THEN 4
                    ELSE 5
                END,
                PPHRowID
        ) AS DeduplicationRank
    FROM stg.PPH_Clean
)
SELECT
    PPHRowID,
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
FROM RankedRows
WHERE DeduplicationRank = 1;
GO

CREATE   VIEW [stg].[vwMedicare_Deduplicated]
AS
WITH RankedRows AS
(
    SELECT
        MedicareCleanID,
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
        LoadedAt,

        ROW_NUMBER() OVER
        (
            PARTITION BY
                FinancialYearStart,
                GeographicUnit,
                GeographicCode,
                ServiceLevel,
                Service,
                MeasureName,
                DemographicGroup
            ORDER BY
                CASE SourceWorksheet
                    WHEN N'Table 2' THEN 1
                    WHEN N'Table 3' THEN 2
                    WHEN N'Table 4' THEN 3
                    WHEN N'Table 5' THEN 4
                    ELSE 5
                END,
                MedicareCleanID
        ) AS DeduplicationRank

    FROM stg.Medicare_Clean
)
SELECT
    MedicareCleanID,
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
FROM RankedRows
WHERE DeduplicationRank = 1;
GO
