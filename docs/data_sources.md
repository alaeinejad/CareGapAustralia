# Data sources and reproducibility

The project uses published government aggregate data. This source register describes the snapshots expected by the packaged SQL, not necessarily the newest releases on the providers' websites.

## Official source register

| Source | Project snapshot | Official reference |
|---|---|---|
| AIHW PPH, catalogue HPF 76 | FY 2017–18 to 2023–24 | [Report and downloadable data](https://www.aihw.gov.au/reports/primary-health-care/potentially-preventable-hospitalisations-2017-2024/data) |
| AIHW Medicare, catalogue PHC 19 | FY 2017–18 to 2024–25 | [Report and downloadable data](https://www.aihw.gov.au/reports/primary-health-care/medicare-subsidised-gp-allied-health-specialist/data) |
| ABS SEIFA | 2021 Census; SA3 distributions | [SEIFA release](https://www.abs.gov.au/statistics/people/people-and-communities/socio-economic-indexes-areas-seifa-australia/latest-release) and [2021 methodology](https://www.abs.gov.au/methodologies/socio-economic-indexes-areas-seifa-australia-methodology/2021) |
| Health Workforce Data | 2024; medical practitioners, General practice, Number of Practitioners, SA3 | [Health Workforce Data Tool](https://www.hwd.health.gov.au/datatool/index.html) |

Provider links supply definitions and download context. The SQL export is the authority for implemented object names and logic. Original download timestamps, source-file checksums and the original workbook conversion code have not been included in this package.

## Input files

All paths below are relative to `SourceRoot` in [00_config.sql](../sql/00_config.sql). The folder must be accessible to the SQL Server service account; a path visible only on the SSMS client is insufficient.

### PPH

| Relative path | Encoding | Preparation |
|---|---|---|
| `AIHW_PPH/aihw-hpf-76-csv-file-2017-18-to-2023-24.csv` | Windows-1252 | Original AIHW combined CSV, with header row |

The importer uses `CODEPAGE='1252'`; the project history recorded incorrect en-dash characters when this file was interpreted as UTF-8. Do not change its encoding assumption without inspecting a new source file.

### Medicare

Each original CSV uses Windows-1252 and a header row. [15_import_medicare.sql](../sql/15_import_medicare.sql) passes the filename to the import procedure for audit and duplicate-load checking.

| Relative path | Financial year |
|---|---|
| `AIHW_Medicare/aihw-phc-019-csv-file-1718-1819/aihw-phc-19-csv_file_1718.csv` | 2017–18 |
| `AIHW_Medicare/aihw-phc-019-csv-file-1718-1819/aihw-phc-19-csv_file_1819.csv` | 2018–19 |
| `AIHW_Medicare/aihw-phc-019-csv-file-1920-2021/aihw-phc-19-csv_file_1920.csv` | 2019–20 |
| `AIHW_Medicare/aihw-phc-019-csv-file-1920-2021/aihw-phc-19-csv_file_2021.csv` | 2020–21 |
| `AIHW_Medicare/aihw-phc-019-csv-file-2122-2223/aihw-phc-19-csv_file_2122.csv` | 2021–22 |
| `AIHW_Medicare/aihw-phc-019-csv-file-2122-2223/aihw-phc-19-csv_file_2223.csv` | 2022–23 |
| `AIHW_Medicare/aihw-phc-019-csv-file-2324-2425/aihw-phc-19-csv_file_2324.csv` | 2023–24 |
| `AIHW_Medicare/aihw-phc-019-csv-file-2324-2425/aihw-phc-19-csv_file_2425.csv` | 2024–25 |

### Prepared SEIFA and workforce inputs

| Relative path | Encoding | Input requirement |
|---|---|---|
| `ABS_SEIFA/seifa_sa3_2021_distribution.csv` | UTF-8 | Long-format SA3 population distributions by index and score category |
| `ABS_SEIFA/seifa_sa3_2021_irsd_summary.csv` | UTF-8 | SA3 IRSD counts, availability flag and population shares |
| `HWD/Workforce_GP_SA3_2024.csv` | UTF-8 | Two columns: SA3 code and practitioner headcount; header row; no Total or blank trailing records |

These are project-prepared inputs, not interchangeable with the original workbook or an arbitrary dashboard download. SQL bulk loading depends on column **order**, not header spelling.

The exact SEIFA column orders are those in `stg.SEIFA_Distribution_Raw` and `stg.SEIFA_IRSD_Summary_Raw` in [02_staging_tables.sql](../sql/02_staging_tables.sql). SEIFA excluded-population indicators are expected to be convertible to `bit`; population shares are decimal fractions, not percentages. Open-ended score bounds may be blank.

The workforce loader expects 335 source records, including `99999`, and 334 matched SA3 fact records after excluding that code. These are snapshot-specific loader expectations, not a general count of Australian SA3 regions. The source selector was labelled ASGS 2023. Matching codes to the warehouse does not verify equivalent geographic boundaries.

## Data availability and provenance

Unavailable observations are retained through statuses rather than silently converted into measured zero values. Medicare retains raw value text, source filename, batch ID and load time. PPH facts point back to clean source row IDs and worksheets; they do not carry the same per-file audit fields as Medicare. SEIFA and workforce retain the provenance fields supported by their current tables.

No raw data or prepared CSVs are embedded in the SQL archive. Download the specified releases and prepare the required CSVs separately. That preparation step is not automated by this repository version, so reproducibility currently depends on obtaining those prepared inputs or reconstructing them from the source workbooks with the documented schema.

## Before extending to a new release

Check source definitions, geographic vintage, worksheet naming, column order, flags, numeric representation and encoding. The current PPH and Medicare staging year constraints cover the documented snapshots, and workforce matching checks are fixed to 2024. New releases require deliberate changes to those constraints and cohort rules.

Record downloaded filenames, release dates, transformations and checksums when adding a reproducible source manifest. Keep source attribution alongside derived outputs. Patient-level interpretation, causal claims and fuel/travel estimates are outside the current source coverage.
