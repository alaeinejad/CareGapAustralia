-- Load original project snapshots into the freshly installed schema.
-- Run once, after 00_install.sql. Some stages reject nonempty target tables.
-- To resume a failed stage, inspect its rollback, then execute that stage and later stages
-- in SQLCMD mode after loading 00_config.sql; do not repeat successful raw imports.
-- SourceRoot layout:
-- AIHW_PPH/aihw-hpf-76-csv-file-2017-18-to-2023-24.csv (original Windows-1252)
-- AIHW_Medicare/aihw-phc-019-csv-file-1718-1819/aihw-phc-19-csv_file_1718.csv
-- ... all eight file paths are listed in 15_import_medicare.sql (original Windows-1252)
-- ABS_SEIFA/seifa_sa3_2021_distribution.csv (project-prepared UTF-8 CSV)
-- ABS_SEIFA/seifa_sa3_2021_irsd_summary.csv (project-prepared UTF-8 CSV)
-- HWD/Workforce_GP_SA3_2024.csv (project-prepared UTF-8 CSV)
-- Retains published counts, rates and percentages as supplied: never sum overlapping
-- categories or geographies, and divide percent-point values by 100 for percentage display.
:on error exit
:r 00_config.sql
:r 11_import_pph.sql
:r 12_clean_pph.sql
:r 13_load_pph_dimensions.sql
:r 14_load_pph_fact.sql
:r 15_import_medicare.sql
:r 16_clean_medicare.sql
:r 17_load_medicare_dimensions.sql
:r 18_load_medicare_fact.sql
:r 19_import_seifa.sql
:r 20_load_seifa.sql
:r 21_import_workforce.sql
:r 22_load_workforce.sql
:r 23_seed_scoring_scenarios.sql
:r 24_etl_validation.sql
