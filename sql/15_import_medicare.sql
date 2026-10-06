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
-- Eight original AIHW Medicare CSVs. Sequential imports; shared landing table.
EXEC stg.usp_LoadMedicareCsv @FilePath = N'$(SourceRoot)\AIHW_Medicare\aihw-phc-019-csv-file-1718-1819\aihw-phc-19-csv_file_1718.csv', @SourceFileName = N'aihw-phc-19-csv_file_1718.csv';
EXEC stg.usp_LoadMedicareCsv @FilePath = N'$(SourceRoot)\AIHW_Medicare\aihw-phc-019-csv-file-1718-1819\aihw-phc-19-csv_file_1819.csv', @SourceFileName = N'aihw-phc-19-csv_file_1819.csv';
EXEC stg.usp_LoadMedicareCsv @FilePath = N'$(SourceRoot)\AIHW_Medicare\aihw-phc-019-csv-file-1920-2021\aihw-phc-19-csv_file_1920.csv', @SourceFileName = N'aihw-phc-19-csv_file_1920.csv';
EXEC stg.usp_LoadMedicareCsv @FilePath = N'$(SourceRoot)\AIHW_Medicare\aihw-phc-019-csv-file-1920-2021\aihw-phc-19-csv_file_2021.csv', @SourceFileName = N'aihw-phc-19-csv_file_2021.csv';
EXEC stg.usp_LoadMedicareCsv @FilePath = N'$(SourceRoot)\AIHW_Medicare\aihw-phc-019-csv-file-2122-2223\aihw-phc-19-csv_file_2122.csv', @SourceFileName = N'aihw-phc-19-csv_file_2122.csv';
EXEC stg.usp_LoadMedicareCsv @FilePath = N'$(SourceRoot)\AIHW_Medicare\aihw-phc-019-csv-file-2122-2223\aihw-phc-19-csv_file_2223.csv', @SourceFileName = N'aihw-phc-19-csv_file_2223.csv';
EXEC stg.usp_LoadMedicareCsv @FilePath = N'$(SourceRoot)\AIHW_Medicare\aihw-phc-019-csv-file-2324-2425\aihw-phc-19-csv_file_2324.csv', @SourceFileName = N'aihw-phc-19-csv_file_2324.csv';
EXEC stg.usp_LoadMedicareCsv @FilePath = N'$(SourceRoot)\AIHW_Medicare\aihw-phc-019-csv-file-2324-2425\aihw-phc-19-csv_file_2425.csv', @SourceFileName = N'aihw-phc-19-csv_file_2425.csv';
GO
