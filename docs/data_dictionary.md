# Data dictionary

This dictionary is derived from the exported SQL schema. Object and column names match the current package; it is not a patient-level clinical dictionary.

## Naming and units

`dw` holds dimensional tables, `stg` holds source and cleaned staging structures, and `rpt` exposes reporting views. Identity keys identify rows; financial and calendar year keys use the documented year values. Geography requires both unit and code.

A fact's `MeasureValue` has no universal unit: use its measure dimension. Decimal precision does not imply that published source data have that level of measurement accuracy. Null means no stored numeric value, not automatically zero.

PPH percentages retain source percentage-point units. Medicare reporting divides by `DimMedicareMeasure.ScaleDivisor`; coverage is therefore a decimal fraction in the analytical view. SEIFA share fields are decimal fractions. Interpret source values and analytical values separately.

## Shared data statuses

| Key | Status | IsValueAvailable |
|---|---|---:|
| 1 | Published | 1 |
| 2 | Not published | 0 |
| 3 | Not applicable | 0 |
| 4 | Nil or rounded to zero | 0 |
| 5 | Other missing | 0 |
| 6 | Not provided | 0 |
| 7 | Partial-year data | 1 |
| 8 | Population proportion capped | 1 |

These are implemented project status mappings. In the current fact constraints, PPH permits a non-null value only with status 1; Medicare permits non-null values for statuses 1, 7 and 8, and null values for statuses 3 and 6. Other missing Medicare patterns require investigation rather than bypassing the constraints. Source flags and descriptions remain available in staging.

## Warehouse tables

The following types and nullability come from [03_dimensions.sql](../sql/03_dimensions.sql) and [04_fact_tables.sql](../sql/04_fact_tables.sql). Defaults and foreign-key/check constraints are defined in [05_indexes_constraints.sql](../sql/05_indexes_constraints.sql).

### `dw.DimFinancialYear`

Financial-year labels and July-to-June boundaries. The key is the start year: 2023 means FY 2023–24.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `FinancialYearKey` | `int` | No | — |
| `FinancialYearLabel` | `nvarchar(7)` | No | — |
| `StartDate` | `date` | No | — |
| `EndDate` | `date` | No | — |

### `dw.DimGeography`

Geographic unit, code, area label, state and peer group. Natural key: GeographicUnit + GeographicCode. Aggregate flags support cohort exclusions.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `GeographyKey` | `int` | No | Yes |
| `GeographicUnit` | `nvarchar(20)` | No | — |
| `GeographicCode` | `nvarchar(30)` | No | — |
| `GeographicAreaName` | `nvarchar(200)` | No | — |
| `StateTerritory` | `nvarchar(50)` | Yes | — |
| `GeographicGroup` | `nvarchar(200)` | Yes | — |
| `IsNational` | `bit` | No | — |
| `IsAggregateArea` | `bit` | No | — |

### `dw.DimDemographic`

Published demographic classification and display order. CanSumAcrossGroups and InterpretationNote warn about overlapping groups.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `DemographicKey` | `tinyint` | No | Yes |
| `DemographicGroup` | `nvarchar(50)` | No | — |
| `DemographicType` | `nvarchar(20)` | No | — |
| `SortOrder` | `tinyint` | No | — |
| `CanSumAcrossGroups` | `bit` | No | — |
| `InterpretationNote` | `nvarchar(300)` | No | — |

### `dw.DimCondition`

PPH group/condition combinations, total/category roles and overlap guidance. Natural key: PPHGroup + PPHCondition.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `ConditionKey` | `smallint` | No | Yes |
| `PPHGroup` | `nvarchar(100)` | No | — |
| `PPHCondition` | `nvarchar(200)` | No | — |
| `IsTotalCondition` | `bit` | No | — |
| `ConditionRole` | `nvarchar(50)` | No | — |
| `CanSumAcrossConditions` | `bit` | No | — |
| `InterpretationNote` | `nvarchar(300)` | No | — |

### `dw.DimMeasure`

PPH measure names, units, display formats and aggregation rules.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `MeasureKey` | `tinyint` | No | Yes |
| `MeasureName` | `nvarchar(200)` | No | — |
| `UnitOfMeasure` | `nvarchar(50)` | No | — |
| `PreferredFormat` | `nvarchar(30)` | No | — |
| `AggregationRule` | `nvarchar(200)` | No | — |

### `dw.DimDataStatus`

Shared numeric-availability and caution statuses. Keys are explicitly assigned rather than generated.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `DataStatusKey` | `tinyint` | No | — |
| `DataStatus` | `nvarchar(50)` | No | — |
| `IsValueAvailable` | `bit` | No | — |
| `StatusDescription` | `nvarchar(200)` | No | — |

### `dw.FactPPH`

PPH values at financial year × geography × demographic × condition × measure. Data status is an attribute, not an extra fact grain dimension.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `FactPPHKey` | `bigint` | No | Yes |
| `FinancialYearKey` | `int` | No | — |
| `GeographyKey` | `int` | No | — |
| `DemographicKey` | `tinyint` | No | — |
| `ConditionKey` | `smallint` | No | — |
| `MeasureKey` | `tinyint` | No | — |
| `DataStatusKey` | `tinyint` | No | — |
| `MeasureValue` | `decimal(19, 4)` | Yes | — |
| `SourcePPHRowID` | `bigint` | No | — |
| `SourceWorksheet` | `nvarchar(50)` | No | — |

### `dw.DimService`

Medicare service levels and service names. Natural key: ServiceLevel + Service. Parent/child service levels can overlap.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `ServiceKey` | `smallint` | No | Yes |
| `ServiceLevel` | `nvarchar(50)` | No | — |
| `ServiceLevelNumber` | `tinyint` | No | — |
| `Service` | `nvarchar(500)` | No | — |
| `CanSumAcrossServices` | `bit` | No | — |
| `InterpretationNote` | `nvarchar(300)` | No | — |

### `dw.DimMedicareMeasure`

Medicare measure units and scaling. ScaleDivisor=100 for the patient-coverage percentage; AnalyticsValue is already scaled by the reporting view.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `MedicareMeasureKey` | `tinyint` | No | Yes |
| `MeasureName` | `nvarchar(300)` | No | — |
| `UnitOfMeasure` | `nvarchar(50)` | No | — |
| `ScaleDivisor` | `decimal(10, 2)` | No | — |
| `PreferredFormat` | `nvarchar(30)` | No | — |
| `AggregationRule` | `nvarchar(300)` | No | — |

### `dw.FactMedicareService`

Medicare values at financial year × geography × demographic × service × measure, with source-row and file provenance.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `FactMedicareServiceKey` | `bigint` | No | Yes |
| `FinancialYearKey` | `int` | No | — |
| `GeographyKey` | `int` | No | — |
| `DemographicKey` | `tinyint` | No | — |
| `ServiceKey` | `smallint` | No | — |
| `MedicareMeasureKey` | `tinyint` | No | — |
| `DataStatusKey` | `tinyint` | No | — |
| `MeasureValue` | `decimal(28, 6)` | Yes | — |
| `SourceMedicareCleanID` | `bigint` | No | — |
| `SourceWorksheet` | `nvarchar(50)` | No | — |
| `SourceFileName` | `nvarchar(260)` | No | — |

### `dw.FactSEIFASA3Summary`

IRSD population counts and shares at geography × SEIFA reference year. Shares use the denominator named in each column.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `FactSEIFASA3SummaryKey` | `bigint` | No | Yes |
| `GeographyKey` | `int` | No | — |
| `SEIFAReferenceYear` | `smallint` | No | — |
| `IRSDPopulationTotal` | `int` | No | — |
| `IRSDPopulationIncluded` | `int` | No | — |
| `IRSDPopulationExcluded` | `int` | No | — |
| `IsIRSDDistributionAvailable` | `bit` | No | — |
| `IRSDLowestDecilePopulation` | `int` | No | — |
| `IRSDMiddleDecilesPopulation` | `int` | No | — |
| `IRSDHighestDecilePopulation` | `int` | No | — |
| `IRSDLowestDecileShareTotalPopulation` | `decimal(18, 8)` | No | — |
| `IRSDLowestDecileShareIncludedPopulation` | `decimal(18, 8)` | Yes | — |
| `IRSDHighestDecileShareTotalPopulation` | `decimal(18, 8)` | No | — |
| `IRSDExcludedPopulationShare` | `decimal(18, 8)` | No | — |
| `SourceFileName` | `nvarchar(400)` | No | — |

### `dw.DimScoringScenario`

Four V1 sensitivity specifications. ScenarioCode is unique; the four weights must sum to 1. Workforce weights are not part of this table.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `ScoringScenarioKey` | `tinyint` | No | Yes |
| `ScenarioCode` | `nvarchar(30)` | No | — |
| `ScenarioName` | `nvarchar(100)` | No | — |
| `ScenarioDescription` | `nvarchar(500)` | No | — |
| `PPHWeight` | `decimal(5, 4)` | No | — |
| `GPServiceWeight` | `decimal(5, 4)` | No | — |
| `GPCoverageWeight` | `decimal(5, 4)` | No | — |
| `IRSDWeight` | `decimal(5, 4)` | No | — |
| `IsBaselineScenario` | `bit` | No | — |

### `dw.DimCalendarYear`

Calendar-year labels and January-to-December boundaries, used for workforce.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `CalendarYearKey` | `smallint` | No | — |
| `CalendarYear` | `smallint` | No | — |
| `YearStartDate` | `date` | No | — |
| `YearEndDate` | `date` | No | — |
| `YearLabel` | `nvarchar(10)` | No | — |

### `dw.DimWorkforceCategory`

Profession, specialty, measure and units. Natural key: Profession + PrimarySpecialty + MeasureName.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `WorkforceCategoryKey` | `smallint` | No | Yes |
| `Profession` | `nvarchar(200)` | No | — |
| `PrimarySpecialty` | `nvarchar(200)` | No | — |
| `MeasureName` | `nvarchar(200)` | No | — |
| `UnitOfMeasure` | `nvarchar(100)` | No | — |
| `AggregationRule` | `nvarchar(400)` | No | — |

### `dw.FactWorkforce`

Practitioner headcounts at calendar year × geography × workforce category, with source and warehouse load metadata.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `FactWorkforceKey` | `bigint` | No | Yes |
| `CalendarYearKey` | `smallint` | No | — |
| `GeographyKey` | `int` | No | — |
| `WorkforceCategoryKey` | `smallint` | No | — |
| `PractitionerCount` | `int` | No | — |
| `GeographyStandard` | `nvarchar(30)` | No | — |
| `SourceFileName` | `nvarchar(260)` | No | — |
| `SourceLoadedAt` | `datetime2(0)` | No | — |
| `DWLoadedAt` | `datetime2(0)` | No | — |

### `dw.DimSEIFAIndex`

Index definitions for IRSD, IRSAD, IER and IEO. Natural key: SEIFAIndexCode.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `SEIFAIndexKey` | `tinyint` | No | Yes |
| `SEIFAIndexCode` | `nvarchar(10)` | No | — |
| `SEIFAIndexName` | `nvarchar(200)` | No | — |
| `IndexDescription` | `nvarchar(600)` | No | — |
| `LowScoreMeaning` | `nvarchar(300)` | No | — |
| `HighScoreMeaning` | `nvarchar(300)` | No | — |

### `dw.DimSEIFAScoreCategory`

Population-distribution score bands and excluded-population category. Natural key: ScoreCategoryNumber; open score bounds may be null.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `SEIFAScoreCategoryKey` | `tinyint` | No | Yes |
| `ScoreCategoryNumber` | `tinyint` | No | — |
| `ScoreCategoryLabel` | `nvarchar(100)` | No | — |
| `ScoreLowerBound` | `smallint` | Yes | — |
| `ScoreUpperBound` | `smallint` | Yes | — |
| `IsExcludedPopulation` | `bit` | No | — |

### `dw.FactSEIFADistribution`

Population count at geography × reference year × SEIFA index × score category.

| Column | SQL type | Nullable | Identity |
|---|---|---|---|
| `FactSEIFADistributionKey` | `bigint` | No | Yes |
| `GeographyKey` | `int` | No | — |
| `SEIFAReferenceYear` | `smallint` | No | — |
| `SEIFAIndexKey` | `tinyint` | No | — |
| `SEIFAScoreCategoryKey` | `tinyint` | No | — |
| `PopulationCount` | `int` | No | — |
| `SourceColumn` | `nvarchar(200)` | No | — |

## Reporting interfaces

| View | Role |
|---|---|
| `rpt.vwPPHAnalysis` | Joined PPH fact, measure, status and dimension metadata |
| `rpt.vwMedicareAnalysis` | Joined Medicare metadata, source values and scaled AnalyticsValue |
| `rpt.vwCareGapSA3` | Matched and unmatched SA3 indicator records, coverage flags and population difference |
| `rpt.vwCareGapSA3Comparable` | Records with both PPH and Medicare coverage |
| `rpt.vwCareGapSA3Analytic` | Complete-case indicators and initial percentiles/score |
| `rpt.vwCareGapSA3Ranked` | Initial national, state and peer scores/ranks |
| `rpt.vwSEIFASA3Analysis` | IRSD summary values with geography and percentage displays |
| `rpt.vwCareGapPriorityV1` | Four-component priority score and ranks |
| `rpt.vwCareGapPriorityV1Explain` | V1 component contributions and relative priority tiers |
| `rpt.vwCareGapSensitivity` | V1 scores and ranks under the scenario weights |
| `rpt.vwGPWorkforceAccess` | GP headcount, population, GPs per 10,000 and residents per GP |
| `rpt.vwCareGapPriorityV2` | Five-component score for FY 2023–24 / workforce 2024 |
| `rpt.vwCareGapPriorityV2Explain` | V2 contributions and V1-to-V2 rank differences |
| `rpt.vwCareGapDashboardV2` | Selected V2 dashboard indicators, ranks and source filenames |

## Important dashboard fields

| Field | Unit / meaning |
|---|---|
| `PPHRateAgeStandardised` | Published hospitalisations per 100,000 people; not an additive count |
| `GPServicesPer100People` | Published GP service-use intensity per 100 people |
| `GPPopulationCoverage` | Decimal fraction after Medicare scaling |
| `IRSDLowestDecileShareTotalPopulation` | Lowest-decile population / total SA3 population |
| `GPPractitionerCount` | Practitioner headcount; not FTE capacity |
| `GPWorkforcePopulation` | Population denominator selected for the workforce ratio |
| `GPsPer10000Residents` | Practitioner count × 10,000 / population |
| `ResidentsPerGP` | Population / practitioner count |
| `CareGapPriorityScoreV1`, `CareGapPriorityScoreV2` | Weighted relative scores, 0–100; not probabilities |
| `NationalPriorityRankV1`, `NationalPriorityRankV2` | Descending score ranks, with ties sharing a rank |
| `NationalRankChangeV1ToV2` | V1 national rank minus V2 national rank; positive means a smaller rank number in V2, subject to cohort differences |
| V2 contribution fields | Rounded points contributed by each of the five weighted percentile components |
| `WorkforceSourceFileName`, `PopulationSourceFileName` | Available source-file provenance |

The exact selected columns are in [07_reporting_views.sql](../sql/07_reporting_views.sql). See [Methodology](methodology.md) for cohort-specific percentile calculations and interpretation.

## Staging inventory

| Table | Function |
|---|---|
| `stg.PPH_Raw` | Original text fields for PPH import |
| `stg.PPH_Clean` | Typed PPH values, flags and original/standardised geography codes |
| `stg.Medicare_Landing` | Shared temporary landing structure for sequential CSV imports |
| `stg.Medicare_Raw` | Imported text plus filename, batch and load timestamp |
| `stg.Medicare_Clean` | Typed/scaled-source preparation, flags, numeric availability and raw values |
| `stg.SEIFA_Distribution_Raw` | Text input for the active SEIFA distribution clean view |
| `stg.SEIFA_IRSD_Summary_Raw` | Text input for the active IRSD summary clean view |
| `stg.SEIFA_Distribution` | Earlier typed staging structure; retained in the schema export |
| `stg.SEIFA_IRSD_Summary` | Earlier typed summary structure; retained in the schema export |
| `stg.WorkforceGP` | Earlier pilot staging structure; not used by the current national fact loader |
| `stg.WorkforceGP_NationalRaw` | Active two-column national workforce source |

Staging column definitions and import order are in [02_staging_tables.sql](../sql/02_staging_tables.sql). Their exact CSV requirements are described in [Data sources](data_sources.md).
