# Analytical methodology

This document describes the implemented reporting logic in [07_reporting_views.sql](../sql/07_reporting_views.sql). Scores support comparative investigation; they are not estimates of the probability of unmet need, validated clinical risk scores or evidence of a causal effect.

## Scope and analytical grain

PPH spans financial years 2017–18 to 2023–24. Medicare spans 2017–18 to 2024–25. The matched PPH/Medicare analysis therefore cannot extend beyond 2023–24. SEIFA uses the 2021 snapshot; workforce uses calendar year 2024.

The local-area comparison selects non-aggregate SA3 geographies and `All persons`. PPH uses the reported `Total PPH` group and condition. GP utilisation uses `GP attendances (total)` at service level 1. Other geographic levels and condition-specific PPH records remain available in the underlying reporting views; they are not mixed into the SA3 priority score.

## Cleaning and deduplication

| Dataset | Implemented treatment |
|---|---|
| PPH | Import Windows-1252 text; trim fields and trailing carriage returns; parse numeric values; preserve raw geography codes; repair the two documented SEIFA endpoint codes |
| Medicare | Import Windows-1252 text; standardise financial-year and selected geographic labels; remove currency, percent and thousands separators before numeric conversion; retain raw values, flags and file/batch audit fields |
| SEIFA | Import project-prepared UTF-8 CSVs into text columns; clean views use `TRY_CONVERT` for counts, shares and nullable open score bounds |
| Workforce | Import a prepared two-column UTF-8 CSV; remove carriage returns; parse headcounts; exclude source code `99999`; require 334 matched SA3 records for this snapshot |

PPH deduplication partitions by year, geographic unit/code, demographic group, PPH group/condition and measure. It prioritises `Table1`, then `Table2`, `Table3`, `Table4`, followed by source row ID. Medicare partitions by year, geographic unit/code, service level/service, measure and demographic group. It prioritises `Table 2`, then `Table 3`, `Table 4`, `Table 5`, followed by source row ID.

These views select preferred records; they do not test whether duplicate values disagree. Conflicting duplicate values require a separate audit. Historical duplicate-resolution choices should be revisited if new source releases change worksheet content.

Missing and suppressed values stay distinguishable from published values. Conversion failures can become null; nullability and status constraints catch some failures, but a conversion audit is still needed before trusting a new release.

## Cohort construction

| View | Eligibility / output |
|---|---|
| `vwCareGapSA3` | Full outer join of PPH and GP indicators by financial year and geography; keeps coverage flags and population differences |
| `vwCareGapSA3Comparable` | Requires both a PPH record and a Medicare record |
| `vwCareGapSA3Analytic` | Requires available PPH and GP service rates plus non-null PPH rate, GP service intensity and GP coverage |
| `vwCareGapPriorityV1` | Inner joins eligible analytic records to available IRSD distribution summaries |
| `vwCareGapPriorityV2` | Joins V1 to GP workforce availability; restricts analysis to FY 2023–24 and workforce calendar year 2024 |

Missing areas are excluded from eligible scoring cohorts, not assigned zero need. The comparison view also exposes `PopulationDifferencePercent`; the current SQL does not apply a population-difference exclusion threshold.

Workforce headcounts are divided by the Medicare-derived resident population for the financial year ending in the same calendar year. This is a time-alignment assumption, not evidence that both measures refer to identical dates or boundaries.

## Indicators

| Indicator | Basis | Interpretation |
|---|---|---|
| PPH pressure | Published age-standardised PPH rate per 100,000 people | Higher rates increase the pressure component |
| GP service intensity | Published GP services per 100 people | Lower rates increase the low-use component |
| GP coverage | Published percentage receiving the GP service, divided by the measure's scale divisor | Lower coverage increases the low-coverage component |
| IRSD disadvantage | Population in the lowest national IRSD decile divided by total SA3 population, as supplied in the prepared summary | Higher shares increase the disadvantage component |
| GP availability | Practitioner headcount × 10,000 / resident population | Lower availability increases the workforce component |
| Residents per GP | Resident population / practitioner headcount | Descriptive workforce ratio; not a separate score component |

The IRSD score uses the total-population share, not the included-population share. Excluded SEIFA populations and alternative denominators are exposed in the warehouse and should accompany interpretation.

## Scores, weights and ranks

Each component uses SQL `PERCENT_RANK()` in the specified cohort, with financial year as the partition. Higher values indicate the direction associated with higher priority. PPH and IRSD are ordered ascending; GP use, coverage and workforce availability are ordered descending.

The score is `100 × SUM(weight × component percentile)`, stored to two decimal places. A score of 80 is not an 80% probability of unmet healthcare need.

| Component | Initial exploratory score | V1 | V2 |
|---|---:|---:|---:|
| PPH pressure | 60% | 50% | 42.5% |
| Low GP service use | 25% | 20% | 17% |
| Low GP coverage | 15% | 10% | 8.5% |
| IRSD disadvantage | — | 20% | 17% |
| Low GP workforce availability | — | — | 15% |

The V2 specification gives workforce 15% and multiplies each V1 weight by 0.85. These weights are project design assumptions. Component contribution views explain the score and allow small rounding differences to be inspected.

Cohorts are **not recomputed uniformly for all components**. PPH, service-use and coverage percentiles are inherited from the analytic cohort; V1 computes IRSD percentiles after its IRSD join; V2 computes workforce percentiles after its workforce join. Consequently, components may use different comparison populations. This must be considered before interpreting V1-to-V2 rank changes.

National and state ranks use `DENSE_RANK()` with higher scores first; tied scores share a rank. Initial peer scores recompute the three components within `GeographicGroup`. V1 peer rankings instead rank its national-component score within that group. V1-to-V2 rank differences also reflect possible cohort changes, rather than only the added workforce weight.

## Sensitivity scenarios

`DimScoringScenario` and `vwCareGapSensitivity` implement four **V1** weight specifications:

| Scenario | PPH | GP services | GP coverage | IRSD |
|---|---:|---:|---:|---:|
| Balanced V1 | 50% | 20% | 10% | 20% |
| Outcome focused | 65% | 15% | 5% | 15% |
| Access focused | 40% | 30% | 20% | 10% |
| Equity focused | 40% | 15% | 10% | 35% |

These scenarios vary weights while retaining the underlying V1 data and percentiles. They do not test workforce weights, alternative geography mappings, missing-data methods or new denominators. A full V2 sensitivity analysis remains future work.

## Aggregation and interpretation

Use reported Total PPH rather than summing conditions or categories, which can overlap. Demographic classifications, service hierarchies and geographic levels also overlap. Rates, age-standardised rates, percentages and length-of-stay measures should not be summed.

For percentage displays, distinguish source percentage-point values from the decimal fractions already produced by analytical views. Do not divide an already scaled value a second time. GP patient counts are service-use counts as defined by the source, not patient-level records linking GP visits to hospitalisations.

Low GP utilisation is a signal for investigation, not direct proof of restricted access. Workforce headcount does not measure full-time equivalent capacity, appointment access or distance to a service. SEIFA describes areas rather than individuals. The current analysis does not measure travel burden, fuel consumption, intervention effectiveness or causal relationships.
