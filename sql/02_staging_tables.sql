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
CREATE TABLE [stg].[SEIFA_Distribution_Raw](
	[SEIFAReferenceYear] [nvarchar](50) NULL,
	[GeographicUnit] [nvarchar](50) NULL,
	[SA3Code] [nvarchar](50) NULL,
	[SA3Name] [nvarchar](400) NULL,
	[SEIFAIndex] [nvarchar](50) NULL,
	[ScoreCategoryNumber] [nvarchar](50) NULL,
	[ScoreCategoryLabel] [nvarchar](100) NULL,
	[ScoreLowerBound] [nvarchar](50) NULL,
	[ScoreUpperBound] [nvarchar](50) NULL,
	[IsExcludedSA1Population] [nvarchar](50) NULL,
	[PopulationCount] [nvarchar](50) NULL,
	[SourceColumn] [nvarchar](200) NULL
) ON [PRIMARY]
GO

CREATE TABLE [stg].[SEIFA_IRSD_Summary_Raw](
	[SEIFAReferenceYear] [nvarchar](50) NULL,
	[GeographicUnit] [nvarchar](50) NULL,
	[SA3Code] [nvarchar](50) NULL,
	[SA3Name] [nvarchar](400) NULL,
	[IRSDPopulationTotal] [nvarchar](50) NULL,
	[IRSDPopulationIncluded] [nvarchar](50) NULL,
	[IRSDPopulationExcluded] [nvarchar](50) NULL,
	[IsIRSDDistributionAvailable] [nvarchar](50) NULL,
	[IRSDLowestDecilePopulation] [nvarchar](50) NULL,
	[IRSDMiddleDecilesPopulation] [nvarchar](50) NULL,
	[IRSDHighestDecilePopulation] [nvarchar](50) NULL,
	[IRSDLowestDecileShareTotalPopulation] [nvarchar](100) NULL,
	[IRSDLowestDecileShareIncludedPopulation] [nvarchar](100) NULL,
	[IRSDHighestDecileShareTotalPopulation] [nvarchar](100) NULL,
	[IRSDExcludedPopulationShare] [nvarchar](100) NULL,
	[SourceFileName] [nvarchar](400) NULL
) ON [PRIMARY]
GO

CREATE TABLE [stg].[PPH_Clean](
	[PPHRowID] [bigint] IDENTITY(1,1) NOT NULL,
	[SourceCode] [nvarchar](20) NOT NULL,
	[DataSource] [nvarchar](200) NOT NULL,
	[ReleaseName] [nvarchar](500) NOT NULL,
	[SourceWorksheet] [nvarchar](50) NOT NULL,
	[FinancialYear] [nvarchar](7) NOT NULL,
	[FinancialYearStart] [smallint] NOT NULL,
	[StateTerritory] [nvarchar](50) NULL,
	[GeographicUnit] [nvarchar](20) NOT NULL,
	[RawGeographicCode] [nvarchar](30) NULL,
	[GeographicCode] [nvarchar](30) NOT NULL,
	[GeographicAreaName] [nvarchar](200) NOT NULL,
	[GeographicGroup] [nvarchar](200) NULL,
	[DemographicGroup] [nvarchar](50) NOT NULL,
	[PPHGroup] [nvarchar](100) NOT NULL,
	[PPHCondition] [nvarchar](200) NOT NULL,
	[MeasureName] [nvarchar](200) NOT NULL,
	[MeasureValue] [decimal](19, 4) NULL,
	[Flag] [nvarchar](20) NULL,
	[FlagExplanation] [nvarchar](100) NULL,
	[IsPublished] [bit] NOT NULL,
 CONSTRAINT [PK_PPH_Clean] PRIMARY KEY CLUSTERED 
(
	[PPHRowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [stg].[Medicare_Clean](
	[MedicareCleanID] [bigint] IDENTITY(1,1) NOT NULL,
	[SourceCode] [nvarchar](20) NOT NULL,
	[DataSource] [nvarchar](200) NOT NULL,
	[ReleaseName] [nvarchar](500) NOT NULL,
	[SourceWorksheet] [nvarchar](50) NOT NULL,
	[FinancialYear] [nvarchar](7) NOT NULL,
	[FinancialYearStart] [smallint] NOT NULL,
	[StateTerritory] [nvarchar](50) NULL,
	[RawGeographicUnit] [nvarchar](20) NULL,
	[GeographicUnit] [nvarchar](20) NOT NULL,
	[GeographicCode] [nvarchar](30) NOT NULL,
	[GeographicAreaName] [nvarchar](200) NOT NULL,
	[GeographicGroup] [nvarchar](200) NULL,
	[ServiceLevel] [nvarchar](50) NOT NULL,
	[Service] [nvarchar](500) NOT NULL,
	[MeasureName] [nvarchar](300) NOT NULL,
	[DemographicGroup] [nvarchar](100) NOT NULL,
	[RawMeasureValue] [nvarchar](50) NULL,
	[MeasureValue] [decimal](28, 6) NULL,
	[Flag] [nvarchar](20) NULL,
	[FlagExplanation] [nvarchar](300) NULL,
	[DataStatus] [nvarchar](100) NOT NULL,
	[IsValueAvailable] [bit] NOT NULL,
	[IsCautionFlag] [bit] NOT NULL,
	[SourceFileName] [nvarchar](260) NOT NULL,
	[LoadBatchID] [uniqueidentifier] NOT NULL,
	[LoadedAt] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_Medicare_Clean] PRIMARY KEY CLUSTERED 
(
	[MedicareCleanID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [stg].[Medicare_Landing](
	[Code] [nvarchar](20) NULL,
	[DataSource] [nvarchar](200) NULL,
	[Name] [nvarchar](500) NULL,
	[Worksheet] [nvarchar](50) NULL,
	[Year] [nvarchar](20) NULL,
	[StateTerritory] [nvarchar](50) NULL,
	[GeographicUnit] [nvarchar](20) NULL,
	[GeographicCode] [nvarchar](30) NULL,
	[GeographicAreaName] [nvarchar](200) NULL,
	[GeographicGroup] [nvarchar](200) NULL,
	[ServiceLevel] [nvarchar](50) NULL,
	[Service] [nvarchar](500) NULL,
	[MeasureName] [nvarchar](300) NULL,
	[DemographicGroup] [nvarchar](100) NULL,
	[MeasureValue] [nvarchar](50) NULL,
	[Flag] [nvarchar](20) NULL,
	[FlagExplanation] [nvarchar](300) NULL
) ON [PRIMARY]
GO

CREATE TABLE [stg].[Medicare_Raw](
	[MedicareRawID] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](20) NULL,
	[DataSource] [nvarchar](200) NULL,
	[Name] [nvarchar](500) NULL,
	[Worksheet] [nvarchar](50) NULL,
	[Year] [nvarchar](20) NULL,
	[StateTerritory] [nvarchar](50) NULL,
	[GeographicUnit] [nvarchar](20) NULL,
	[GeographicCode] [nvarchar](30) NULL,
	[GeographicAreaName] [nvarchar](200) NULL,
	[GeographicGroup] [nvarchar](200) NULL,
	[ServiceLevel] [nvarchar](50) NULL,
	[Service] [nvarchar](500) NULL,
	[MeasureName] [nvarchar](300) NULL,
	[DemographicGroup] [nvarchar](100) NULL,
	[MeasureValue] [nvarchar](50) NULL,
	[Flag] [nvarchar](20) NULL,
	[FlagExplanation] [nvarchar](300) NULL,
	[SourceFileName] [nvarchar](260) NOT NULL,
	[LoadBatchID] [uniqueidentifier] NOT NULL,
	[LoadedAt] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_Medicare_Raw] PRIMARY KEY CLUSTERED 
(
	[MedicareRawID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [stg].[PPH_Raw](
	[Code] [nvarchar](20) NULL,
	[DataSource] [nvarchar](200) NULL,
	[Name] [nvarchar](500) NULL,
	[Worksheet] [nvarchar](50) NULL,
	[Year] [nvarchar](20) NULL,
	[StateTerritory] [nvarchar](50) NULL,
	[GeographicUnit] [nvarchar](20) NULL,
	[GeographicCode] [nvarchar](30) NULL,
	[GeographicAreaName] [nvarchar](200) NULL,
	[GeographicGroup] [nvarchar](200) NULL,
	[DemographicGroup] [nvarchar](50) NULL,
	[PPHGroup] [nvarchar](100) NULL,
	[PPHCondition] [nvarchar](200) NULL,
	[MeasureName] [nvarchar](200) NULL,
	[MeasureValue] [nvarchar](50) NULL,
	[Flag] [nvarchar](20) NULL,
	[FlagExplanation] [nvarchar](100) NULL
) ON [PRIMARY]
GO

CREATE TABLE [stg].[SEIFA_Distribution](
	[SEIFAReferenceYear] [smallint] NOT NULL,
	[GeographicUnit] [nvarchar](10) NOT NULL,
	[SA3Code] [nvarchar](10) NOT NULL,
	[SA3Name] [nvarchar](200) NOT NULL,
	[SEIFAIndex] [nvarchar](10) NOT NULL,
	[ScoreCategoryNumber] [tinyint] NOT NULL,
	[ScoreCategoryLabel] [nvarchar](50) NOT NULL,
	[ScoreLowerBound] [smallint] NULL,
	[ScoreUpperBound] [smallint] NULL,
	[IsExcludedSA1Population] [bit] NOT NULL,
	[PopulationCount] [int] NOT NULL,
	[SourceColumn] [nvarchar](100) NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [stg].[SEIFA_IRSD_Summary](
	[SEIFAReferenceYear] [smallint] NOT NULL,
	[GeographicUnit] [nvarchar](10) NOT NULL,
	[SA3Code] [nvarchar](10) NOT NULL,
	[SA3Name] [nvarchar](200) NOT NULL,
	[IRSDPopulationTotal] [int] NOT NULL,
	[IRSDPopulationIncluded] [int] NOT NULL,
	[IRSDPopulationExcluded] [int] NOT NULL,
	[IsIRSDDistributionAvailable] [bit] NOT NULL,
	[IRSDLowestDecilePopulation] [int] NOT NULL,
	[IRSDMiddleDecilesPopulation] [int] NOT NULL,
	[IRSDHighestDecilePopulation] [int] NOT NULL,
	[IRSDLowestDecileShareTotalPopulation] [decimal](18, 8) NOT NULL,
	[IRSDLowestDecileShareIncludedPopulation] [decimal](18, 8) NULL,
	[IRSDHighestDecileShareTotalPopulation] [decimal](18, 8) NOT NULL,
	[IRSDExcludedPopulationShare] [decimal](18, 8) NOT NULL,
	[SourceFileName] [nvarchar](300) NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [stg].[WorkforceGP](
	[WorkforceGPStageID] [int] IDENTITY(1,1) NOT NULL,
	[ReferenceYear] [smallint] NOT NULL,
	[GeographyStandard] [nvarchar](30) NOT NULL,
	[GeographicUnit] [nvarchar](20) NOT NULL,
	[GeographicCode] [nvarchar](20) NOT NULL,
	[GeographicAreaName] [nvarchar](200) NOT NULL,
	[Profession] [nvarchar](200) NOT NULL,
	[PrimarySpecialty] [nvarchar](200) NOT NULL,
	[MeasureName] [nvarchar](200) NOT NULL,
	[PractitionerCount] [int] NOT NULL,
	[SourceFileName] [nvarchar](260) NOT NULL,
	[LoadedAt] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_WorkforceGP] PRIMARY KEY CLUSTERED 
(
	[WorkforceGPStageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [stg].[WorkforceGP_NationalRaw](
	[SA3CodeRaw] [nvarchar](50) NULL,
	[PractitionerCountRaw] [nvarchar](50) NULL
) ON [PRIMARY]
GO
