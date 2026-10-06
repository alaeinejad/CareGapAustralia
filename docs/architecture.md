# Architecture and SQL execution

CareGap Australia uses a dimensional warehouse to keep published healthcare measures, their interpretation and their source context together. This document describes the SQL package as prepared for the repository; it does not certify a successful clean deployment.

Related documents: [Methodology](methodology.md), [Data sources](data_sources.md), [Data dictionary](data_dictionary.md).

## Layers

| Layer | Objects | Purpose |
|---|---|---|
| Ingestion | `stg.PPH_Raw`, `stg.Medicare_Landing`, `stg.Medicare_Raw`, SEIFA raw tables, `stg.WorkforceGP_NationalRaw` | Preserve imported source fields; Medicare also records filename, batch and load time |
| Cleaning | `stg.PPH_Clean`, `stg.Medicare_Clean`, SEIFA clean views | Trim strings, convert values, standardise selected labels and retain availability flags |
| Deduplication | `stg.vwPPH_Deduplicated`, `stg.vwMedicare_Deduplicated` | Select one published worksheet record at the intended analytical grain |
| Warehouse | 13 dimension tables and five fact tables in `dw` | Provide shared keys, measure metadata and protected fact grains |
| Reporting | 14 views in `rpt` | Join indicators, define eligible cohorts and calculate scores, contributions and rankings |
| Presentation | Power BI report developed for the project | Explore indicators through the reporting layer; [CareGapAustralia.pbix](../powerbi/CareGapAustralia.pbix) is included in the repository |

There are 29 tables in the exported schema: 18 warehouse tables and 11 staging tables. Four staging views and 14 reporting views make 18 views in total. The export contains one stored procedure, `stg.usp_LoadMedicareCsv`. Some staging tables retain earlier project structures; the current national workforce loader reads `WorkforceGP_NationalRaw` directly, rather than loading the seven-area pilot through `WorkforceGP`.

## Fact grains and dimensions

| Fact | One row represents | Main dimensions |
|---|---|---|
| `FactPPH` | Financial year × geography × demographic group × PPH group/condition × measure | Financial year, geography, demographic, condition, measure, data status |
| `FactMedicareService` | Financial year × geography × demographic group × service level/service × measure | Financial year, geography, demographic, service, Medicare measure, data status |
| `FactSEIFADistribution` | Geography × reference year × SEIFA index × score category | Geography, SEIFA index, score category |
| `FactSEIFASA3Summary` | Geography × SEIFA reference year | Geography; reference year is stored in the fact |
| `FactWorkforce` | Calendar year × geography × workforce category | Calendar year, geography, workforce category |

`DimGeography` uses `(GeographicUnit, GeographicCode)` as its natural key. This prevents equal-looking codes at different geographic levels from being treated as the same region. The dimension is initially populated from PPH; later loaders require source geographies to match those members.

## Execution order

All entry points use SQLCMD directives. Run from the `sql` folder, or resolve include paths explicitly when using SSMS SQLCMD Mode.

| Entry point / group | Role |
|---|---|
| [00_config.sql](../sql/00_config.sql) | Database name and server-accessible source root |
| [00_install.sql](../sql/00_install.sql) | Create an unused database and include schema scripts 01–09 |
| Scripts 01–08 | Schemas; staging tables; dimensions; facts; indexes and constraints; staging views; reporting views; import procedure |
| [09_validation.sql](../sql/09_validation.sql) | Schema inventory, row counts and constraint checks |
| [10_run_etl.sql](../sql/10_run_etl.sql) | Include the data-loading workflow 11–24 |
| Scripts 11–14 | PPH import, cleaning, dimensions and fact |
| Scripts 15–18 | Medicare imports, cleaning, dimension extensions and fact |
| Scripts 19–20 | Prepared SEIFA CSV imports and warehouse loads |
| Scripts 21–22 | Prepared national workforce CSV import and 2024 fact load |
| Script 23 | Four V1 scoring scenarios |
| [24_etl_validation.sql](../sql/24_etl_validation.sql) | Reconcile source and fact counts and inspect the dashboard view |

## Reliability and reproducibility

Primary and unique keys protect dimensional members and fact grains. Foreign keys protect relationships. Check constraints enforce supported value/status combinations. PPH and Medicare use clustered columnstore indexes, while other tables use the exported rowstore structures.

Most reconstructed ETL stages use `XACT_ABORT` and transaction error handling. Several stages require empty targets, so this is a fresh-build workflow rather than a general incremental pipeline. Medicare imports run sequentially because they share a landing table. The workforce stage replaces only its selected year/category within a transaction.

Count reconciliation catches records lost through dimension joins. It does not prove that source values, geography boundaries or scores are scientifically valid. A failed stage must be inspected before resuming; successful raw imports should not be repeated blindly.

Static checks have covered insert column names, required columns, included filenames and basic object dependency order. SQL Server execution, source-file availability and end-to-end analytical outputs remain to be verified for this packaged version. The [Power BI report](../powerbi/CareGapAustralia.pbix) is included in the repository, but opening it and refreshing its data have not been verified in this review. Source datasets and the original workbook-to-CSV conversion are not included.
