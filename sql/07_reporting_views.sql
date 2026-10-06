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
CREATE   VIEW [rpt].[vwPPHAnalysis]
AS
SELECT
    F.FactPPHKey,

    FY.FinancialYearKey,
    FY.FinancialYearLabel,
    FY.StartDate AS FinancialYearStartDate,
    FY.EndDate AS FinancialYearEndDate,

    G.GeographyKey,
    G.GeographicUnit,
    G.GeographicCode,
    G.GeographicAreaName,
    G.StateTerritory,
    G.GeographicGroup,
    G.IsNational,
    G.IsAggregateArea,

    D.DemographicKey,
    D.DemographicGroup,
    D.DemographicType,
    D.SortOrder AS DemographicSortOrder,

    C.ConditionKey,
    C.PPHGroup,
    C.PPHCondition,
    C.IsTotalCondition,

    M.MeasureKey,
    M.MeasureName,
    M.UnitOfMeasure,
    M.PreferredFormat,
    M.AggregationRule,

    DS.DataStatusKey,
    DS.DataStatus,
    DS.IsValueAvailable,
    DS.StatusDescription,

    F.MeasureValue,
    F.SourceWorksheet,
    F.SourcePPHRowID
FROM dw.FactPPH AS F
INNER JOIN dw.DimFinancialYear AS FY
    ON FY.FinancialYearKey = F.FinancialYearKey
INNER JOIN dw.DimGeography AS G
    ON G.GeographyKey = F.GeographyKey
INNER JOIN dw.DimDemographic AS D
    ON D.DemographicKey = F.DemographicKey
INNER JOIN dw.DimCondition AS C
    ON C.ConditionKey = F.ConditionKey
INNER JOIN dw.DimMeasure AS M
    ON M.MeasureKey = F.MeasureKey
INNER JOIN dw.DimDataStatus AS DS
    ON DS.DataStatusKey = F.DataStatusKey;
GO

CREATE   VIEW [rpt].[vwMedicareAnalysis]
AS
SELECT
    F.FactMedicareServiceKey,

    FY.FinancialYearKey,
    FY.FinancialYearLabel,
    FY.StartDate AS FinancialYearStartDate,
    FY.EndDate AS FinancialYearEndDate,

    G.GeographyKey,
    G.GeographicUnit,
    G.GeographicCode,
    G.GeographicAreaName,
    G.StateTerritory,
    G.GeographicGroup,
    G.IsNational,
    G.IsAggregateArea,

    D.DemographicKey,
    D.DemographicGroup,
    D.DemographicType,
    D.SortOrder AS DemographicSortOrder,
    D.CanSumAcrossGroups,

    S.ServiceKey,
    S.ServiceLevel,
    S.ServiceLevelNumber,
    S.Service,
    S.CanSumAcrossServices,

    M.MedicareMeasureKey,
    M.MeasureName,
    M.UnitOfMeasure,
    M.ScaleDivisor,
    M.PreferredFormat,
    M.AggregationRule,

    DS.DataStatusKey,
    DS.DataStatus,
    DS.IsValueAvailable,
    DS.StatusDescription,

    F.MeasureValue AS SourceMeasureValue,

    CAST(
        F.MeasureValue / NULLIF(M.ScaleDivisor, 0)
        AS DECIMAL(28,8)
    ) AS AnalyticsValue,

    CASE
        WHEN F.DataStatusKey IN (7, 8) THEN 1
        ELSE 0
    END AS IsCautionFlag,

    F.SourceWorksheet,
    F.SourceFileName,
    F.SourceMedicareCleanID

FROM dw.FactMedicareService AS F

INNER JOIN dw.DimFinancialYear AS FY
    ON FY.FinancialYearKey = F.FinancialYearKey

INNER JOIN dw.DimGeography AS G
    ON G.GeographyKey = F.GeographyKey

INNER JOIN dw.DimDemographic AS D
    ON D.DemographicKey = F.DemographicKey

INNER JOIN dw.DimService AS S
    ON S.ServiceKey = F.ServiceKey

INNER JOIN dw.DimMedicareMeasure AS M
    ON M.MedicareMeasureKey = F.MedicareMeasureKey

INNER JOIN dw.DimDataStatus AS DS
    ON DS.DataStatusKey = F.DataStatusKey;
GO

CREATE   VIEW [rpt].[vwCareGapSA3]
AS

WITH PPH AS
(
    SELECT
        FinancialYearKey,
        FinancialYearLabel,
        FinancialYearStartDate,
        FinancialYearEndDate,
        GeographyKey,
        GeographicUnit,
        GeographicCode,
        GeographicAreaName,
        StateTerritory,
        GeographicGroup,

        MAX(CASE
            WHEN MeasureName = N'Estimated resident population'
            THEN MeasureValue
        END) AS PPHPopulation,

        MAX(CASE
            WHEN MeasureName = N'Number of hospitalisations'
            THEN MeasureValue
        END) AS PPHHospitalisations,

        MAX(CASE
            WHEN MeasureName =
                 N'Hospitalisations per 100,000 people (age-standardised)'
            THEN MeasureValue
        END) AS PPHRateAgeStandardised,

        MAX(CASE
            WHEN MeasureName =
                 N'Hospitalisations per 100,000 people (crude)'
            THEN MeasureValue
        END) AS PPHRateCrude,

        MAX(CASE
            WHEN MeasureName = N'Total bed days'
            THEN MeasureValue
        END) AS PPHBedDays,

        MAX(CASE
            WHEN MeasureName = N'Average length of stay (days)'
            THEN MeasureValue
        END) AS PPHAverageLengthOfStay,

        MAX(CASE
            WHEN MeasureName =
                 N'Hospitalisations per 100,000 people (age-standardised)'
            THEN DataStatus
        END) AS PPHRateDataStatus,

        MAX(CASE
            WHEN MeasureName =
                 N'Hospitalisations per 100,000 people (age-standardised)'
                 AND IsValueAvailable = 1
            THEN 1 ELSE 0
        END) AS IsPPHRateAvailable

    FROM rpt.vwPPHAnalysis
    WHERE GeographicUnit = N'SA3'
      AND IsAggregateArea = 0
      AND DemographicGroup = N'All persons'
      AND PPHGroup = N'Total PPH'
      AND PPHCondition = N'Total PPH'
    GROUP BY
        FinancialYearKey,
        FinancialYearLabel,
        FinancialYearStartDate,
        FinancialYearEndDate,
        GeographyKey,
        GeographicUnit,
        GeographicCode,
        GeographicAreaName,
        StateTerritory,
        GeographicGroup
),
Medicare AS
(
    SELECT
        FinancialYearKey,
        FinancialYearLabel,
        FinancialYearStartDate,
        FinancialYearEndDate,
        GeographyKey,
        GeographicUnit,
        GeographicCode,
        GeographicAreaName,
        StateTerritory,
        GeographicGroup,

        MAX(CASE
            WHEN MeasureName = N'Estimated resident population'
            THEN SourceMeasureValue
        END) AS MedicarePopulation,

        MAX(CASE
            WHEN MeasureName = N'No. patients'
            THEN SourceMeasureValue
        END) AS GPPatients,

        MAX(CASE
            WHEN MeasureName = N'No. services'
            THEN SourceMeasureValue
        END) AS GPServices,

        MAX(CASE
            WHEN MeasureName =
                 N'Percentage of people who had the service (%)'
            THEN AnalyticsValue
        END) AS GPPopulationCoverage,

        MAX(CASE
            WHEN MeasureName = N'Services per 100 people'
            THEN SourceMeasureValue
        END) AS GPServicesPer100People,

        MAX(CASE
            WHEN MeasureName = N'Medicare benefits per 100 people ($)'
            THEN SourceMeasureValue
        END) AS GPBenefitsPer100People,

        MAX(CASE
            WHEN MeasureName = N'Total Medicare benefits paid ($)'
            THEN SourceMeasureValue
        END) AS GPTotalMedicareBenefits,

        MAX(CASE
            WHEN MeasureName = N'Total provider fees ($)'
            THEN SourceMeasureValue
        END) AS GPTotalProviderFees,

        MAX(CASE
            WHEN MeasureName = N'Services per 100 people'
            THEN DataStatus
        END) AS GPServiceRateDataStatus,

        MAX(CASE
            WHEN MeasureName = N'Services per 100 people'
                 AND IsValueAvailable = 1
            THEN 1 ELSE 0
        END) AS IsGPServiceRateAvailable,

        MAX(CASE
            WHEN IsCautionFlag = 1
            THEN 1 ELSE 0
        END) AS HasMedicareCautionFlag

    FROM rpt.vwMedicareAnalysis
    WHERE GeographicUnit = N'SA3'
      AND IsAggregateArea = 0
      AND DemographicGroup = N'All persons'
      AND ServiceLevelNumber = 1
      AND Service = N'GP attendances (total)'
    GROUP BY
        FinancialYearKey,
        FinancialYearLabel,
        FinancialYearStartDate,
        FinancialYearEndDate,
        GeographyKey,
        GeographicUnit,
        GeographicCode,
        GeographicAreaName,
        StateTerritory,
        GeographicGroup
)
SELECT
    COALESCE(p.FinancialYearKey, m.FinancialYearKey)
        AS FinancialYearKey,

    COALESCE(p.FinancialYearLabel, m.FinancialYearLabel)
        AS FinancialYearLabel,

    COALESCE(p.FinancialYearStartDate, m.FinancialYearStartDate)
        AS FinancialYearStartDate,

    COALESCE(p.FinancialYearEndDate, m.FinancialYearEndDate)
        AS FinancialYearEndDate,

    COALESCE(p.GeographyKey, m.GeographyKey)
        AS GeographyKey,

    COALESCE(p.GeographicUnit, m.GeographicUnit)
        AS GeographicUnit,

    COALESCE(p.GeographicCode, m.GeographicCode)
        AS GeographicCode,

    COALESCE(p.GeographicAreaName, m.GeographicAreaName)
        AS GeographicAreaName,

    COALESCE(p.StateTerritory, m.StateTerritory)
        AS StateTerritory,

    COALESCE(p.GeographicGroup, m.GeographicGroup)
        AS GeographicGroup,

    CASE WHEN p.GeographyKey IS NOT NULL THEN 1 ELSE 0 END
        AS HasPPHRecord,

    CASE WHEN m.GeographyKey IS NOT NULL THEN 1 ELSE 0 END
        AS HasMedicareRecord,

    p.PPHPopulation,
    p.PPHHospitalisations,
    p.PPHRateAgeStandardised,
    p.PPHRateCrude,
    p.PPHBedDays,
    p.PPHAverageLengthOfStay,
    p.PPHRateDataStatus,
    p.IsPPHRateAvailable,

    m.MedicarePopulation,
    m.GPPatients,
    m.GPServices,
    m.GPPopulationCoverage,
    m.GPServicesPer100People,
    m.GPBenefitsPer100People,
    m.GPTotalMedicareBenefits,
    m.GPTotalProviderFees,
    m.GPServiceRateDataStatus,
    m.IsGPServiceRateAvailable,
    m.HasMedicareCautionFlag,

    CASE
        WHEN p.PPHPopulation IS NOT NULL
         AND m.MedicarePopulation IS NOT NULL
         AND p.PPHPopulation <> 0
        THEN
            (
                (m.MedicarePopulation - p.PPHPopulation)
                / p.PPHPopulation
            ) * 100.0
    END AS PopulationDifferencePercent

FROM PPH AS p
FULL OUTER JOIN Medicare AS m
    ON m.FinancialYearKey = p.FinancialYearKey
   AND m.GeographyKey = p.GeographyKey;
GO

CREATE   VIEW [rpt].[vwCareGapSA3Comparable]
AS
SELECT *
FROM rpt.vwCareGapSA3
WHERE HasPPHRecord = 1
  AND HasMedicareRecord = 1;
GO

CREATE   VIEW [rpt].[vwCareGapSA3Analytic]
AS

WITH CompleteCases AS
(
    SELECT
        FinancialYearKey,
        FinancialYearLabel,
        FinancialYearStartDate,
        FinancialYearEndDate,
        GeographyKey,
        GeographicCode,
        GeographicAreaName,
        StateTerritory,
        GeographicGroup,

        PPHPopulation,
        PPHHospitalisations,
        PPHRateAgeStandardised,
        PPHRateCrude,
        PPHBedDays,
        PPHAverageLengthOfStay,

        MedicarePopulation,
        GPPatients,
        GPServices,
        GPPopulationCoverage,
        GPServicesPer100People,
        GPBenefitsPer100People,
        GPTotalMedicareBenefits,
        GPTotalProviderFees,

        PopulationDifferencePercent
    FROM rpt.vwCareGapSA3Comparable
    WHERE IsPPHRateAvailable = 1
      AND IsGPServiceRateAvailable = 1
      AND PPHRateAgeStandardised IS NOT NULL
      AND GPServicesPer100People IS NOT NULL
      AND GPPopulationCoverage IS NOT NULL
),
Ranked AS
(
    SELECT
        *,

        PERCENT_RANK() OVER
        (
            PARTITION BY FinancialYearKey
            ORDER BY PPHRateAgeStandardised
        ) AS PPHPressurePercentile,

        PERCENT_RANK() OVER
        (
            PARTITION BY FinancialYearKey
            ORDER BY GPServicesPer100People DESC
        ) AS LowGPServicePercentile,

        PERCENT_RANK() OVER
        (
            PARTITION BY FinancialYearKey
            ORDER BY GPPopulationCoverage DESC
        ) AS LowGPCoveragePercentile

    FROM CompleteCases
)
SELECT
    *,

    CAST
    (
        100.0 *
        (
              0.60 * PPHPressurePercentile
            + 0.25 * LowGPServicePercentile
            + 0.15 * LowGPCoveragePercentile
        )
        AS decimal(6,2)
    ) AS ExploratoryCareGapScore

FROM Ranked;
GO

CREATE   VIEW [rpt].[vwCareGapSA3Ranked]
AS

WITH PeerComponents AS
(
    SELECT
        a.*,

        PERCENT_RANK() OVER
        (
            PARTITION BY FinancialYearKey, GeographicGroup
            ORDER BY PPHRateAgeStandardised
        ) AS PeerPPHPressurePercentile,

        PERCENT_RANK() OVER
        (
            PARTITION BY FinancialYearKey, GeographicGroup
            ORDER BY GPServicesPer100People DESC
        ) AS PeerLowGPServicePercentile,

        PERCENT_RANK() OVER
        (
            PARTITION BY FinancialYearKey, GeographicGroup
            ORDER BY GPPopulationCoverage DESC
        ) AS PeerLowGPCoveragePercentile

    FROM rpt.vwCareGapSA3Analytic AS a
),
Scores AS
(
    SELECT
        *,

        CAST
        (
            100.0 *
            (
                  0.60 * PeerPPHPressurePercentile
                + 0.25 * PeerLowGPServicePercentile
                + 0.15 * PeerLowGPCoveragePercentile
            )
            AS decimal(6,2)
        ) AS PeerCareGapScore

    FROM PeerComponents
)
SELECT
    *,

    DENSE_RANK() OVER
    (
        PARTITION BY FinancialYearKey
        ORDER BY ExploratoryCareGapScore DESC
    ) AS NationalPriorityRank,

    DENSE_RANK() OVER
    (
        PARTITION BY FinancialYearKey, StateTerritory
        ORDER BY ExploratoryCareGapScore DESC
    ) AS StatePriorityRank,

    DENSE_RANK() OVER
    (
        PARTITION BY FinancialYearKey, GeographicGroup
        ORDER BY PeerCareGapScore DESC
    ) AS PeerGroupPriorityRank,

    COUNT_BIG(*) OVER
    (
        PARTITION BY FinancialYearKey, StateTerritory
    ) AS StateComparableAreaCount,

    COUNT_BIG(*) OVER
    (
        PARTITION BY FinancialYearKey, GeographicGroup
    ) AS PeerComparableAreaCount

FROM Scores;
GO

CREATE   VIEW [rpt].[vwSEIFASA3Analysis]
AS
SELECT
    f.FactSEIFASA3SummaryKey,
    f.GeographyKey,
    g.GeographicUnit,
    g.GeographicCode,
    g.GeographicAreaName,
    g.StateTerritory,
    g.GeographicGroup,
    f.SEIFAReferenceYear,

    f.IRSDPopulationTotal,
    f.IRSDPopulationIncluded,
    f.IRSDPopulationExcluded,
    f.IsIRSDDistributionAvailable,

    f.IRSDLowestDecilePopulation,
    f.IRSDMiddleDecilesPopulation,
    f.IRSDHighestDecilePopulation,

    f.IRSDLowestDecileShareTotalPopulation,
    f.IRSDLowestDecileShareIncludedPopulation,
    f.IRSDHighestDecileShareTotalPopulation,
    f.IRSDExcludedPopulationShare,

    CAST
    (
        f.IRSDLowestDecileShareTotalPopulation * 100.0
        AS decimal(7,2)
    ) AS IRSDLowestDecilePopulationPercent,

    CAST
    (
        f.IRSDHighestDecileShareTotalPopulation * 100.0
        AS decimal(7,2)
    ) AS IRSDHighestDecilePopulationPercent,

    f.SourceFileName

FROM dw.FactSEIFASA3Summary AS f
INNER JOIN dw.DimGeography AS g
    ON g.GeographyKey = f.GeographyKey;
GO

CREATE   VIEW [rpt].[vwCareGapPriorityV1]
AS

WITH JoinedData AS
(
    SELECT
        c.*,

        s.SEIFAReferenceYear,
        s.IRSDPopulationTotal,
        s.IRSDPopulationIncluded,
        s.IRSDPopulationExcluded,
        s.IRSDLowestDecilePopulation,
        s.IRSDMiddleDecilesPopulation,
        s.IRSDHighestDecilePopulation,
        s.IRSDLowestDecileShareTotalPopulation,
        s.IRSDHighestDecileShareTotalPopulation,
        s.IRSDExcludedPopulationShare,
        s.IRSDLowestDecilePopulationPercent,
        s.IRSDHighestDecilePopulationPercent

    FROM rpt.vwCareGapSA3Analytic AS c
    INNER JOIN rpt.vwSEIFASA3Analysis AS s
        ON s.GeographyKey = c.GeographyKey
       AND s.IsIRSDDistributionAvailable = 1
),
Components AS
(
    SELECT
        *,

        PERCENT_RANK() OVER
        (
            PARTITION BY FinancialYearKey
            ORDER BY IRSDLowestDecileShareTotalPopulation
        ) AS IRSDDisadvantagePercentile

    FROM JoinedData
),
Scores AS
(
    SELECT
        *,

        CAST
        (
            100.0 *
            (
                  0.50 * PPHPressurePercentile
                + 0.20 * LowGPServicePercentile
                + 0.10 * LowGPCoveragePercentile
                + 0.20 * IRSDDisadvantagePercentile
            )
            AS decimal(6,2)
        ) AS CareGapPriorityScoreV1

    FROM Components
)
SELECT
    *,

    DENSE_RANK() OVER
    (
        PARTITION BY FinancialYearKey
        ORDER BY CareGapPriorityScoreV1 DESC
    ) AS NationalPriorityRankV1,

    DENSE_RANK() OVER
    (
        PARTITION BY FinancialYearKey, StateTerritory
        ORDER BY CareGapPriorityScoreV1 DESC
    ) AS StatePriorityRankV1,

    DENSE_RANK() OVER
    (
        PARTITION BY FinancialYearKey, GeographicGroup
        ORDER BY CareGapPriorityScoreV1 DESC
    ) AS PeerGroupPriorityRankV1,

    COUNT_BIG(*) OVER
    (
        PARTITION BY FinancialYearKey, StateTerritory
    ) AS StateComparableAreaCount,

    COUNT_BIG(*) OVER
    (
        PARTITION BY FinancialYearKey, GeographicGroup
    ) AS PeerComparableAreaCount

FROM Scores;
GO

CREATE   VIEW [rpt].[vwCareGapPriorityV1Explain]
AS

WITH Explained AS
(
    SELECT
        p.*,

        CAST
        (
            50.0 * PPHPressurePercentile
            AS decimal(6,2)
        ) AS PPHContributionPoints,

        CAST
        (
            20.0 * LowGPServicePercentile
            AS decimal(6,2)
        ) AS LowGPServiceContributionPoints,

        CAST
        (
            10.0 * LowGPCoveragePercentile
            AS decimal(6,2)
        ) AS LowGPCoverageContributionPoints,

        CAST
        (
            20.0 * IRSDDisadvantagePercentile
            AS decimal(6,2)
        ) AS IRSDContributionPoints,

        PERCENT_RANK() OVER
        (
            PARTITION BY FinancialYearKey
            ORDER BY CareGapPriorityScoreV1
        ) AS CareGapScorePercentile,

        COUNT_BIG(*) OVER
        (
            PARTITION BY FinancialYearKey
        ) AS NationalComparableAreaCount

    FROM rpt.vwCareGapPriorityV1 AS p
)
SELECT
    *,

    CAST
    (
          PPHContributionPoints
        + LowGPServiceContributionPoints
        + LowGPCoverageContributionPoints
        + IRSDContributionPoints
        AS decimal(6,2)
    ) AS RecalculatedPriorityScore,

    CAST
    (
        CareGapPriorityScoreV1 -
        (
              PPHContributionPoints
            + LowGPServiceContributionPoints
            + LowGPCoverageContributionPoints
            + IRSDContributionPoints
        )
        AS decimal(6,2)
    ) AS ScoreRoundingDifference,

    CASE
        WHEN CareGapScorePercentile >= 0.90
            THEN N'Very high priority'
        WHEN CareGapScorePercentile >= 0.75
            THEN N'High priority'
        WHEN CareGapScorePercentile >= 0.50
            THEN N'Moderate priority'
        ELSE N'Lower priority'
    END AS PriorityTier

FROM Explained;
GO

CREATE   VIEW [rpt].[vwCareGapSensitivity]
AS

WITH ScenarioScores AS
(
    SELECT
        p.FinancialYearKey,
        p.FinancialYearLabel,
        p.GeographyKey,
        p.GeographicCode,
        p.GeographicAreaName,
        p.StateTerritory,
        p.GeographicGroup,

        p.PPHRateAgeStandardised,
        p.GPServicesPer100People,
        p.GPPopulationCoverage,
        p.IRSDLowestDecilePopulationPercent,

        p.PPHPressurePercentile,
        p.LowGPServicePercentile,
        p.LowGPCoveragePercentile,
        p.IRSDDisadvantagePercentile,

        s.ScoringScenarioKey,
        s.ScenarioCode,
        s.ScenarioName,
        s.IsBaselineScenario,

        s.PPHWeight,
        s.GPServiceWeight,
        s.GPCoverageWeight,
        s.IRSDWeight,

        CAST
        (
            100.0 *
            (
                  s.PPHWeight
                    * p.PPHPressurePercentile
                + s.GPServiceWeight
                    * p.LowGPServicePercentile
                + s.GPCoverageWeight
                    * p.LowGPCoveragePercentile
                + s.IRSDWeight
                    * p.IRSDDisadvantagePercentile
            )
            AS decimal(6,2)
        ) AS ScenarioPriorityScore

    FROM rpt.vwCareGapPriorityV1 AS p
    CROSS JOIN dw.DimScoringScenario AS s
)
SELECT
    *,

    DENSE_RANK() OVER
    (
        PARTITION BY FinancialYearKey, ScoringScenarioKey
        ORDER BY ScenarioPriorityScore DESC
    ) AS NationalScenarioRank,

    DENSE_RANK() OVER
    (
        PARTITION BY
            FinancialYearKey,
            ScoringScenarioKey,
            StateTerritory
        ORDER BY ScenarioPriorityScore DESC
    ) AS StateScenarioRank

FROM ScenarioScores;
GO

CREATE   VIEW [rpt].[vwGPWorkforceAccess]
AS
WITH Population AS
(
    SELECT
        F.FinancialYearKey,
        FY.FinancialYearLabel,
        FY.EndDate,
        F.GeographyKey,
        CAST
        (
            F.MeasureValue / NULLIF(M.ScaleDivisor, 0)
            AS decimal(28,6)
        ) AS EstimatedResidentPopulation,
        DS.DataStatus AS PopulationDataStatus,
        F.SourceFileName AS PopulationSourceFileName
    FROM dw.FactMedicareService AS F
    INNER JOIN dw.DimFinancialYear AS FY
        ON FY.FinancialYearKey = F.FinancialYearKey
    INNER JOIN dw.DimGeography AS G
        ON G.GeographyKey = F.GeographyKey
    INNER JOIN dw.DimDemographic AS D
        ON D.DemographicKey = F.DemographicKey
    INNER JOIN dw.DimService AS S
        ON S.ServiceKey = F.ServiceKey
    INNER JOIN dw.DimMedicareMeasure AS M
        ON M.MedicareMeasureKey = F.MedicareMeasureKey
    INNER JOIN dw.DimDataStatus AS DS
        ON DS.DataStatusKey = F.DataStatusKey
    WHERE G.GeographicUnit = N'SA3'
      AND D.DemographicGroup = N'All persons'
      AND S.Service = N'GP attendances (total)'
      AND M.MeasureName = N'Estimated resident population'
      AND DS.IsValueAvailable = 1
),
WorkforcePopulation AS
(
    SELECT
        W.CalendarYearKey AS WorkforceCalendarYear,
        CY.YearLabel AS WorkforceYearLabel,

        P.FinancialYearKey AS PopulationFinancialYearKey,
        P.FinancialYearLabel AS PopulationFinancialYearLabel,

        G.GeographyKey,
        G.GeographicUnit,
        G.GeographicCode,
        G.GeographicAreaName,
        G.StateTerritory,
        G.GeographicGroup,

        C.Profession,
        C.PrimarySpecialty,
        C.MeasureName AS WorkforceMeasureName,
        C.UnitOfMeasure AS WorkforceUnitOfMeasure,

        W.PractitionerCount,
        P.EstimatedResidentPopulation,

        CAST
        (
            W.PractitionerCount * 10000.0
            / NULLIF(P.EstimatedResidentPopulation, 0)
            AS decimal(18,4)
        ) AS GPsPer10000Residents,

        CAST
        (
            P.EstimatedResidentPopulation
            / NULLIF(W.PractitionerCount * 1.0, 0)
            AS decimal(18,2)
        ) AS ResidentsPerGP,

        P.PopulationDataStatus,
        W.GeographyStandard,
        W.SourceFileName AS WorkforceSourceFileName,
        P.PopulationSourceFileName
    FROM dw.FactWorkforce AS W
    INNER JOIN dw.DimCalendarYear AS CY
        ON CY.CalendarYearKey = W.CalendarYearKey
    INNER JOIN dw.DimGeography AS G
        ON G.GeographyKey = W.GeographyKey
    INNER JOIN dw.DimWorkforceCategory AS C
        ON C.WorkforceCategoryKey = W.WorkforceCategoryKey
    INNER JOIN Population AS P
        ON P.GeographyKey = W.GeographyKey

        /* Workforce 2024 is aligned to FY 2023–24 */
       AND YEAR(P.EndDate) = W.CalendarYearKey

    WHERE C.Profession = N'Medical Practitioners'
      AND C.PrimarySpecialty = N'General practice'
      AND C.MeasureName = N'Number of Practitioners'
)
SELECT
    WorkforceCalendarYear,
    WorkforceYearLabel,
    PopulationFinancialYearKey,
    PopulationFinancialYearLabel,

    GeographyKey,
    GeographicUnit,
    GeographicCode,
    GeographicAreaName,
    StateTerritory,
    GeographicGroup,

    Profession,
    PrimarySpecialty,
    WorkforceMeasureName,
    WorkforceUnitOfMeasure,

    PractitionerCount,
    EstimatedResidentPopulation,
    GPsPer10000Residents,
    ResidentsPerGP,

    DENSE_RANK() OVER
    (
        PARTITION BY WorkforceCalendarYear
        ORDER BY GPsPer10000Residents ASC
    ) AS GPAccessNeedRank,

    DENSE_RANK() OVER
    (
        PARTITION BY WorkforceCalendarYear
        ORDER BY GPsPer10000Residents DESC
    ) AS GPAvailabilityRank,

    PopulationDataStatus,
    GeographyStandard,
    WorkforceSourceFileName,
    PopulationSourceFileName
FROM WorkforcePopulation;
GO

CREATE   VIEW [rpt].[vwCareGapPriorityV2]
AS
WITH Components AS
(
    SELECT
        v.*,
        w.WorkforceCalendarYear,
        w.PractitionerCount AS GPPractitionerCount,
        w.EstimatedResidentPopulation AS GPWorkforcePopulation,
        w.GPsPer10000Residents,
        w.ResidentsPerGP,
        PERCENT_RANK() OVER
        (
            PARTITION BY v.FinancialYearKey
            ORDER BY w.GPsPer10000Residents DESC
        ) AS LowGPWorkforcePercentile
    FROM rpt.vwCareGapPriorityV1 AS v
    INNER JOIN rpt.vwGPWorkforceAccess AS w
        ON w.GeographyKey = v.GeographyKey
       AND w.PopulationFinancialYearKey = v.FinancialYearKey
    WHERE v.FinancialYearKey = 2023
      AND w.WorkforceCalendarYear = 2024
      AND w.Profession = N'Medical Practitioners'
      AND w.PrimarySpecialty = N'General practice'
),
Scores AS
(
    SELECT
        *,
        CAST
        (
            100.0 *
            (
                0.425 * PPHPressurePercentile
              + 0.170 * LowGPServicePercentile
              + 0.085 * LowGPCoveragePercentile
              + 0.170 * IRSDDisadvantagePercentile
              + 0.150 * LowGPWorkforcePercentile
            )
            AS decimal(6,2)
        ) AS CareGapPriorityScoreV2
    FROM Components
)
SELECT
    *,
    DENSE_RANK() OVER
    (
        PARTITION BY FinancialYearKey
        ORDER BY CareGapPriorityScoreV2 DESC
    ) AS NationalPriorityRankV2,
    DENSE_RANK() OVER
    (
        PARTITION BY FinancialYearKey, StateTerritory
        ORDER BY CareGapPriorityScoreV2 DESC
    ) AS StatePriorityRankV2
FROM Scores;
GO

CREATE   VIEW [rpt].[vwCareGapPriorityV2Explain]
AS
WITH Contributions AS
(
    SELECT
        v.*,
        CAST(42.5 * PPHPressurePercentile
            AS decimal(6,2)) AS PPHContributionPointsV2,
        CAST(17.0 * LowGPServicePercentile
            AS decimal(6,2)) AS LowGPServiceContributionPointsV2,
        CAST(8.5 * LowGPCoveragePercentile
            AS decimal(6,2)) AS LowGPCoverageContributionPointsV2,
        CAST(17.0 * IRSDDisadvantagePercentile
            AS decimal(6,2)) AS IRSDContributionPointsV2,
        CAST(15.0 * LowGPWorkforcePercentile
            AS decimal(6,2)) AS LowGPWorkforceContributionPointsV2,
        NationalPriorityRankV1 - NationalPriorityRankV2
            AS NationalRankChangeV1ToV2
    FROM rpt.vwCareGapPriorityV2 AS v
)
SELECT
    *,
    CAST
    (
          PPHContributionPointsV2
        + LowGPServiceContributionPointsV2
        + LowGPCoverageContributionPointsV2
        + IRSDContributionPointsV2
        + LowGPWorkforceContributionPointsV2
        AS decimal(6,2)
    ) AS RecalculatedPriorityScoreV2,
    CAST
    (
        CareGapPriorityScoreV2
        - (
              PPHContributionPointsV2
            + LowGPServiceContributionPointsV2
            + LowGPCoverageContributionPointsV2
            + IRSDContributionPointsV2
            + LowGPWorkforceContributionPointsV2
          )
        AS decimal(6,2)
    ) AS ScoreRoundingDifferenceV2
FROM Contributions;
GO

CREATE   VIEW [rpt].[vwCareGapDashboardV2]
AS
SELECT
    v.FinancialYearKey,
    v.FinancialYearLabel,
    v.WorkforceCalendarYear,
    v.GeographyKey,
    v.GeographicCode,
    v.GeographicAreaName,
    v.StateTerritory,
    v.GeographicGroup,

    v.PPHRateAgeStandardised,
    v.GPServicesPer100People,
    v.GPPopulationCoverage,
    v.IRSDLowestDecileShareTotalPopulation,

    v.GPPractitionerCount,
    v.GPWorkforcePopulation,
    v.GPsPer10000Residents,
    v.ResidentsPerGP,
    v.LowGPWorkforcePercentile,

    v.CareGapPriorityScoreV1,
    v.CareGapPriorityScoreV2,
    v.NationalPriorityRankV1,
    v.NationalPriorityRankV2,
    v.StatePriorityRankV1,
    v.StatePriorityRankV2,
    v.NationalRankChangeV1ToV2,

    v.PPHContributionPointsV2,
    v.LowGPServiceContributionPointsV2,
    v.LowGPCoverageContributionPointsV2,
    v.IRSDContributionPointsV2,
    v.LowGPWorkforceContributionPointsV2,

    w.WorkforceSourceFileName,
    w.PopulationSourceFileName
FROM rpt.vwCareGapPriorityV2Explain AS v
INNER JOIN rpt.vwGPWorkforceAccess AS w
    ON w.GeographyKey = v.GeographyKey
   AND w.PopulationFinancialYearKey = v.FinancialYearKey
   AND w.WorkforceCalendarYear = v.WorkforceCalendarYear
   AND w.Profession = N'Medical Practitioners'
   AND w.PrimarySpecialty = N'General practice';
GO
