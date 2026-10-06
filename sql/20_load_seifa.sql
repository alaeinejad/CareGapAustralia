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
-- Current clean views parse open score bounds; populate both SEIFA facts.
IF EXISTS (SELECT 1 FROM dw.FactSEIFADistribution)
    THROW 50100, 'Expected empty target dw.FactSEIFADistribution; this script is for a fresh build.', 1;
IF EXISTS (SELECT 1 FROM dw.FactSEIFASA3Summary)
    THROW 50100, 'Expected empty target dw.FactSEIFASA3Summary; this script is for a fresh build.', 1;
IF NOT EXISTS (SELECT 1 FROM stg.vwSEIFA_Distribution_Clean)
    THROW 50101, 'Source stg.vwSEIFA_Distribution_Clean is empty.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
INSERT INTO dw.DimSEIFAIndex
(
    SEIFAIndexCode,
    SEIFAIndexName,
    IndexDescription,
    LowScoreMeaning,
    HighScoreMeaning
)
SELECT
    v.SEIFAIndexCode,
    v.SEIFAIndexName,
    v.IndexDescription,
    v.LowScoreMeaning,
    v.HighScoreMeaning
FROM
(
    VALUES
    (
        N'IRSD',
        N'Index of Relative Socio-economic Disadvantage',
        N'Summarises relative socio-economic disadvantage.',
        N'Greater relative disadvantage.',
        N'Relative lack of disadvantage.'
    ),
    (
        N'IRSAD',
        N'Index of Relative Socio-economic Advantage and Disadvantage',
        N'Summarises both relative advantage and disadvantage.',
        N'Greater disadvantage and lack of advantage.',
        N'Greater advantage and lack of disadvantage.'
    ),
    (
        N'IER',
        N'Index of Economic Resources',
        N'Summarises relative access to economic resources.',
        N'Relative lack of economic resources.',
        N'Greater access to economic resources.'
    ),
    (
        N'IEO',
        N'Index of Education and Occupation',
        N'Summarises educational and occupational characteristics.',
        N'Lower education and occupation levels.',
        N'Higher education and occupation levels.'
    )
) AS v
(
    SEIFAIndexCode,
    SEIFAIndexName,
    IndexDescription,
    LowScoreMeaning,
    HighScoreMeaning
)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.DimSEIFAIndex AS d
    WHERE d.SEIFAIndexCode = v.SEIFAIndexCode
);

INSERT INTO dw.DimSEIFAScoreCategory
(
    ScoreCategoryNumber,
    ScoreCategoryLabel,
    ScoreLowerBound,
    ScoreUpperBound,
    IsExcludedPopulation
)
SELECT DISTINCT
    s.ScoreCategoryNumber,
    s.ScoreCategoryLabel,
    s.ScoreLowerBound,
    s.ScoreUpperBound,
    s.IsExcludedSA1Population
FROM stg.vwSEIFA_Distribution_Clean AS s
WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.DimSEIFAScoreCategory AS d
    WHERE d.ScoreCategoryNumber = s.ScoreCategoryNumber
);

INSERT INTO dw.FactSEIFADistribution
(
    GeographyKey,
    SEIFAReferenceYear,
    SEIFAIndexKey,
    SEIFAScoreCategoryKey,
    PopulationCount,
    SourceColumn
)
SELECT
    g.GeographyKey,
    s.SEIFAReferenceYear,
    i.SEIFAIndexKey,
    c.SEIFAScoreCategoryKey,
    s.PopulationCount,
    s.SourceColumn
FROM stg.vwSEIFA_Distribution_Clean AS s
INNER JOIN dw.DimGeography AS g
    ON g.GeographicUnit = N'SA3'
   AND g.GeographicCode = s.SA3Code
INNER JOIN dw.DimSEIFAIndex AS i
    ON i.SEIFAIndexCode = s.SEIFAIndex
INNER JOIN dw.DimSEIFAScoreCategory AS c
    ON c.ScoreCategoryNumber = s.ScoreCategoryNumber;

INSERT INTO dw.FactSEIFASA3Summary
(
    GeographyKey,
    SEIFAReferenceYear,
    IRSDPopulationTotal,
    IRSDPopulationIncluded,
    IRSDPopulationExcluded,
    IsIRSDDistributionAvailable,
    IRSDLowestDecilePopulation,
    IRSDMiddleDecilesPopulation,
    IRSDHighestDecilePopulation,
    IRSDLowestDecileShareTotalPopulation,
    IRSDLowestDecileShareIncludedPopulation,
    IRSDHighestDecileShareTotalPopulation,
    IRSDExcludedPopulationShare,
    SourceFileName
)
SELECT
    g.GeographyKey,
    s.SEIFAReferenceYear,
    s.IRSDPopulationTotal,
    s.IRSDPopulationIncluded,
    s.IRSDPopulationExcluded,
    s.IsIRSDDistributionAvailable,
    s.IRSDLowestDecilePopulation,
    s.IRSDMiddleDecilesPopulation,
    s.IRSDHighestDecilePopulation,
    s.IRSDLowestDecileShareTotalPopulation,
    s.IRSDLowestDecileShareIncludedPopulation,
    s.IRSDHighestDecileShareTotalPopulation,
    s.IRSDExcludedPopulationShare,
    s.SourceFileName
FROM stg.vwSEIFA_IRSD_Summary_Clean AS s
INNER JOIN dw.DimGeography AS g
    ON g.GeographicUnit = N'SA3'
   AND g.GeographicCode = s.SA3Code;
IF (SELECT COUNT_BIG(*) FROM dw.FactSEIFADistribution) <> (SELECT COUNT_BIG(*) FROM stg.vwSEIFA_Distribution_Clean)
    THROW 50102, 'Row reconciliation failed for dw.FactSEIFADistribution; review missing dimension keys.', 1;

IF (SELECT COUNT_BIG(*) FROM dw.FactSEIFASA3Summary) <> (SELECT COUNT_BIG(*) FROM stg.vwSEIFA_IRSD_Summary_Clean)
    THROW 50102, 'Row reconciliation failed for dw.FactSEIFASA3Summary; review missing dimension keys.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
