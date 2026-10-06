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
CREATE   PROCEDURE [stg].[usp_LoadMedicareCsv]
    @FilePath       NVARCHAR(1000),
    @SourceFileName NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS
    (
        SELECT 1
        FROM stg.Medicare_Raw
        WHERE SourceFileName = @SourceFileName
    )
    BEGIN
        THROW 50001,
              'This Medicare source file has already been loaded.',
              1;
    END;

    DECLARE @LoadBatchID UNIQUEIDENTIFIER = NEWID();
    DECLARE @LoadedAt DATETIME2(0) = SYSDATETIME();
    DECLARE @SQL NVARCHAR(MAX);

    BEGIN TRANSACTION;

    TRUNCATE TABLE stg.Medicare_Landing;

    SET @SQL =
        N'BULK INSERT stg.Medicare_Landing
          FROM ''' + REPLACE(@FilePath, '''', '''''') + N'''
          WITH
          (
              FORMAT = ''CSV'',
              FIRSTROW = 2,
              FIELDQUOTE = ''"'',
              CODEPAGE = ''1252'',
              ROWTERMINATOR = ''0x0a'',
              TABLOCK
          );';

    EXEC sys.sp_executesql @SQL;

    IF NOT EXISTS (SELECT 1 FROM stg.Medicare_Landing)
    BEGIN
        THROW 50002,
              'No rows were loaded into Medicare_Landing.',
              1;
    END;

    INSERT INTO stg.Medicare_Raw
    (
        Code,
        DataSource,
        Name,
        Worksheet,
        [Year],
        StateTerritory,
        GeographicUnit,
        GeographicCode,
        GeographicAreaName,
        GeographicGroup,
        ServiceLevel,
        Service,
        MeasureName,
        DemographicGroup,
        MeasureValue,
        Flag,
        FlagExplanation,
        SourceFileName,
        LoadBatchID,
        LoadedAt
    )
    SELECT
        Code,
        DataSource,
        Name,
        Worksheet,
        [Year],
        StateTerritory,
        GeographicUnit,
        GeographicCode,
        GeographicAreaName,
        GeographicGroup,
        ServiceLevel,
        Service,
        MeasureName,
        DemographicGroup,
        MeasureValue,
        Flag,
        FlagExplanation,
        @SourceFileName,
        @LoadBatchID,
        @LoadedAt
    FROM stg.Medicare_Landing;

    DECLARE @RowsLoaded BIGINT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT
        @SourceFileName AS SourceFileName,
        @LoadBatchID AS LoadBatchID,
        @RowsLoaded AS RowsLoaded;
END;
GO
