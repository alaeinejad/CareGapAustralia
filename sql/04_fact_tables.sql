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
CREATE TABLE [dw].[FactPPH](
	[FactPPHKey] [bigint] IDENTITY(1,1) NOT NULL,
	[FinancialYearKey] [int] NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[DemographicKey] [tinyint] NOT NULL,
	[ConditionKey] [smallint] NOT NULL,
	[MeasureKey] [tinyint] NOT NULL,
	[DataStatusKey] [tinyint] NOT NULL,
	[MeasureValue] [decimal](19, 4) NULL,
	[SourcePPHRowID] [bigint] NOT NULL,
	[SourceWorksheet] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_FactPPH] PRIMARY KEY NONCLUSTERED 
(
	[FactPPHKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dw].[FactMedicareService](
	[FactMedicareServiceKey] [bigint] IDENTITY(1,1) NOT NULL,
	[FinancialYearKey] [int] NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[DemographicKey] [tinyint] NOT NULL,
	[ServiceKey] [smallint] NOT NULL,
	[MedicareMeasureKey] [tinyint] NOT NULL,
	[DataStatusKey] [tinyint] NOT NULL,
	[MeasureValue] [decimal](28, 6) NULL,
	[SourceMedicareCleanID] [bigint] NOT NULL,
	[SourceWorksheet] [nvarchar](50) NOT NULL,
	[SourceFileName] [nvarchar](260) NOT NULL,
 CONSTRAINT [PK_FactMedicareService] PRIMARY KEY NONCLUSTERED 
(
	[FactMedicareServiceKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dw].[FactSEIFASA3Summary](
	[FactSEIFASA3SummaryKey] [bigint] IDENTITY(1,1) NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[SEIFAReferenceYear] [smallint] NOT NULL,
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
	[SourceFileName] [nvarchar](400) NOT NULL,
 CONSTRAINT [PK_FactSEIFASA3Summary] PRIMARY KEY CLUSTERED 
(
	[FactSEIFASA3SummaryKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dw].[FactWorkforce](
	[FactWorkforceKey] [bigint] IDENTITY(1,1) NOT NULL,
	[CalendarYearKey] [smallint] NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[WorkforceCategoryKey] [smallint] NOT NULL,
	[PractitionerCount] [int] NOT NULL,
	[GeographyStandard] [nvarchar](30) NOT NULL,
	[SourceFileName] [nvarchar](260) NOT NULL,
	[SourceLoadedAt] [datetime2](0) NOT NULL,
	[DWLoadedAt] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_FactWorkforce] PRIMARY KEY CLUSTERED 
(
	[FactWorkforceKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dw].[FactSEIFADistribution](
	[FactSEIFADistributionKey] [bigint] IDENTITY(1,1) NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[SEIFAReferenceYear] [smallint] NOT NULL,
	[SEIFAIndexKey] [tinyint] NOT NULL,
	[SEIFAScoreCategoryKey] [tinyint] NOT NULL,
	[PopulationCount] [int] NOT NULL,
	[SourceColumn] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_FactSEIFADistribution] PRIMARY KEY CLUSTERED 
(
	[FactSEIFADistributionKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
