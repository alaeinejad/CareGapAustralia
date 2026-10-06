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
CREATE UNIQUE NONCLUSTERED INDEX [UX_DimWorkforceCategory_Grain] ON [dw].[DimWorkforceCategory]
(
	[Profession] ASC,
	[PrimarySpecialty] ASC,
	[MeasureName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_FactMedicareService_Grain] ON [dw].[FactMedicareService]
(
	[FinancialYearKey] ASC,
	[GeographyKey] ASC,
	[DemographicKey] ASC,
	[ServiceKey] ASC,
	[MedicareMeasureKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_FactPPH_Grain] ON [dw].[FactPPH]
(
	[FinancialYearKey] ASC,
	[GeographyKey] ASC,
	[DemographicKey] ASC,
	[ConditionKey] ASC,
	[MeasureKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_FactSEIFADistribution_Grain] ON [dw].[FactSEIFADistribution]
(
	[GeographyKey] ASC,
	[SEIFAReferenceYear] ASC,
	[SEIFAIndexKey] ASC,
	[SEIFAScoreCategoryKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_FactSEIFASA3Summary_Grain] ON [dw].[FactSEIFASA3Summary]
(
	[GeographyKey] ASC,
	[SEIFAReferenceYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_FactWorkforce_Grain] ON [dw].[FactWorkforce]
(
	[CalendarYearKey] ASC,
	[GeographyKey] ASC,
	[WorkforceCategoryKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PPH_Clean_GeographyYear] ON [stg].[PPH_Clean]
(
	[GeographicUnit] ASC,
	[GeographicCode] ASC,
	[FinancialYearStart] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PPH_Clean_Measure] ON [stg].[PPH_Clean]
(
	[MeasureName] ASC,
	[PPHCondition] ASC,
	[DemographicGroup] ASC
)
INCLUDE([FinancialYearStart],[GeographicCode],[MeasureValue],[IsPublished]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CCI_FactMedicareService] ON [dw].[FactMedicareService] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CCI_FactPPH] ON [dw].[FactPPH] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO

ALTER TABLE [dw].[FactWorkforce] ADD  CONSTRAINT [DF_FactWorkforce_DWLoadedAt]  DEFAULT (sysdatetime()) FOR [DWLoadedAt]
GO

ALTER TABLE [stg].[WorkforceGP] ADD  CONSTRAINT [DF_WorkforceGP_LoadedAt]  DEFAULT (sysdatetime()) FOR [LoadedAt]
GO

ALTER TABLE [dw].[FactMedicareService]  WITH CHECK ADD  CONSTRAINT [FK_FactMedicare_DataStatus] FOREIGN KEY([DataStatusKey])
REFERENCES [dw].[DimDataStatus] ([DataStatusKey])
GO

ALTER TABLE [dw].[FactMedicareService] CHECK CONSTRAINT [FK_FactMedicare_DataStatus]
GO

ALTER TABLE [dw].[FactMedicareService]  WITH CHECK ADD  CONSTRAINT [FK_FactMedicare_Demographic] FOREIGN KEY([DemographicKey])
REFERENCES [dw].[DimDemographic] ([DemographicKey])
GO

ALTER TABLE [dw].[FactMedicareService] CHECK CONSTRAINT [FK_FactMedicare_Demographic]
GO

ALTER TABLE [dw].[FactMedicareService]  WITH CHECK ADD  CONSTRAINT [FK_FactMedicare_FinancialYear] FOREIGN KEY([FinancialYearKey])
REFERENCES [dw].[DimFinancialYear] ([FinancialYearKey])
GO

ALTER TABLE [dw].[FactMedicareService] CHECK CONSTRAINT [FK_FactMedicare_FinancialYear]
GO

ALTER TABLE [dw].[FactMedicareService]  WITH CHECK ADD  CONSTRAINT [FK_FactMedicare_Geography] FOREIGN KEY([GeographyKey])
REFERENCES [dw].[DimGeography] ([GeographyKey])
GO

ALTER TABLE [dw].[FactMedicareService] CHECK CONSTRAINT [FK_FactMedicare_Geography]
GO

ALTER TABLE [dw].[FactMedicareService]  WITH CHECK ADD  CONSTRAINT [FK_FactMedicare_Measure] FOREIGN KEY([MedicareMeasureKey])
REFERENCES [dw].[DimMedicareMeasure] ([MedicareMeasureKey])
GO

ALTER TABLE [dw].[FactMedicareService] CHECK CONSTRAINT [FK_FactMedicare_Measure]
GO

ALTER TABLE [dw].[FactMedicareService]  WITH CHECK ADD  CONSTRAINT [FK_FactMedicare_Service] FOREIGN KEY([ServiceKey])
REFERENCES [dw].[DimService] ([ServiceKey])
GO

ALTER TABLE [dw].[FactMedicareService] CHECK CONSTRAINT [FK_FactMedicare_Service]
GO

ALTER TABLE [dw].[FactPPH]  WITH CHECK ADD  CONSTRAINT [FK_FactPPH_Condition] FOREIGN KEY([ConditionKey])
REFERENCES [dw].[DimCondition] ([ConditionKey])
GO

ALTER TABLE [dw].[FactPPH] CHECK CONSTRAINT [FK_FactPPH_Condition]
GO

ALTER TABLE [dw].[FactPPH]  WITH CHECK ADD  CONSTRAINT [FK_FactPPH_DataStatus] FOREIGN KEY([DataStatusKey])
REFERENCES [dw].[DimDataStatus] ([DataStatusKey])
GO

ALTER TABLE [dw].[FactPPH] CHECK CONSTRAINT [FK_FactPPH_DataStatus]
GO

ALTER TABLE [dw].[FactPPH]  WITH CHECK ADD  CONSTRAINT [FK_FactPPH_Demographic] FOREIGN KEY([DemographicKey])
REFERENCES [dw].[DimDemographic] ([DemographicKey])
GO

ALTER TABLE [dw].[FactPPH] CHECK CONSTRAINT [FK_FactPPH_Demographic]
GO

ALTER TABLE [dw].[FactPPH]  WITH CHECK ADD  CONSTRAINT [FK_FactPPH_FinancialYear] FOREIGN KEY([FinancialYearKey])
REFERENCES [dw].[DimFinancialYear] ([FinancialYearKey])
GO

ALTER TABLE [dw].[FactPPH] CHECK CONSTRAINT [FK_FactPPH_FinancialYear]
GO

ALTER TABLE [dw].[FactPPH]  WITH CHECK ADD  CONSTRAINT [FK_FactPPH_Geography] FOREIGN KEY([GeographyKey])
REFERENCES [dw].[DimGeography] ([GeographyKey])
GO

ALTER TABLE [dw].[FactPPH] CHECK CONSTRAINT [FK_FactPPH_Geography]
GO

ALTER TABLE [dw].[FactPPH]  WITH CHECK ADD  CONSTRAINT [FK_FactPPH_Measure] FOREIGN KEY([MeasureKey])
REFERENCES [dw].[DimMeasure] ([MeasureKey])
GO

ALTER TABLE [dw].[FactPPH] CHECK CONSTRAINT [FK_FactPPH_Measure]
GO

ALTER TABLE [dw].[FactSEIFADistribution]  WITH CHECK ADD  CONSTRAINT [FK_FactSEIFADistribution_Category] FOREIGN KEY([SEIFAScoreCategoryKey])
REFERENCES [dw].[DimSEIFAScoreCategory] ([SEIFAScoreCategoryKey])
GO

ALTER TABLE [dw].[FactSEIFADistribution] CHECK CONSTRAINT [FK_FactSEIFADistribution_Category]
GO

ALTER TABLE [dw].[FactSEIFADistribution]  WITH CHECK ADD  CONSTRAINT [FK_FactSEIFADistribution_Geography] FOREIGN KEY([GeographyKey])
REFERENCES [dw].[DimGeography] ([GeographyKey])
GO

ALTER TABLE [dw].[FactSEIFADistribution] CHECK CONSTRAINT [FK_FactSEIFADistribution_Geography]
GO

ALTER TABLE [dw].[FactSEIFADistribution]  WITH CHECK ADD  CONSTRAINT [FK_FactSEIFADistribution_Index] FOREIGN KEY([SEIFAIndexKey])
REFERENCES [dw].[DimSEIFAIndex] ([SEIFAIndexKey])
GO

ALTER TABLE [dw].[FactSEIFADistribution] CHECK CONSTRAINT [FK_FactSEIFADistribution_Index]
GO

ALTER TABLE [dw].[FactSEIFASA3Summary]  WITH CHECK ADD  CONSTRAINT [FK_FactSEIFASA3Summary_Geography] FOREIGN KEY([GeographyKey])
REFERENCES [dw].[DimGeography] ([GeographyKey])
GO

ALTER TABLE [dw].[FactSEIFASA3Summary] CHECK CONSTRAINT [FK_FactSEIFASA3Summary_Geography]
GO

ALTER TABLE [dw].[FactWorkforce]  WITH CHECK ADD  CONSTRAINT [FK_FactWorkforce_CalendarYear] FOREIGN KEY([CalendarYearKey])
REFERENCES [dw].[DimCalendarYear] ([CalendarYearKey])
GO

ALTER TABLE [dw].[FactWorkforce] CHECK CONSTRAINT [FK_FactWorkforce_CalendarYear]
GO

ALTER TABLE [dw].[FactWorkforce]  WITH CHECK ADD  CONSTRAINT [FK_FactWorkforce_Category] FOREIGN KEY([WorkforceCategoryKey])
REFERENCES [dw].[DimWorkforceCategory] ([WorkforceCategoryKey])
GO

ALTER TABLE [dw].[FactWorkforce] CHECK CONSTRAINT [FK_FactWorkforce_Category]
GO

ALTER TABLE [dw].[FactWorkforce]  WITH CHECK ADD  CONSTRAINT [FK_FactWorkforce_Geography] FOREIGN KEY([GeographyKey])
REFERENCES [dw].[DimGeography] ([GeographyKey])
GO

ALTER TABLE [dw].[FactWorkforce] CHECK CONSTRAINT [FK_FactWorkforce_Geography]
GO

ALTER TABLE [dw].[DimScoringScenario]  WITH CHECK ADD  CONSTRAINT [CK_DimScoringScenario_Weights] CHECK  ((((([PPHWeight]+[GPServiceWeight])+[GPCoverageWeight])+[IRSDWeight])=(1.0000)))
GO

ALTER TABLE [dw].[DimScoringScenario] CHECK CONSTRAINT [CK_DimScoringScenario_Weights]
GO

ALTER TABLE [dw].[FactMedicareService]  WITH CHECK ADD  CONSTRAINT [CK_FactMedicare_ValueStatus] CHECK  ((([DataStatusKey]=(8) OR [DataStatusKey]=(7) OR [DataStatusKey]=(1)) AND [MeasureValue] IS NOT NULL OR ([DataStatusKey]=(6) OR [DataStatusKey]=(3)) AND [MeasureValue] IS NULL))
GO

ALTER TABLE [dw].[FactMedicareService] CHECK CONSTRAINT [CK_FactMedicare_ValueStatus]
GO

ALTER TABLE [dw].[FactPPH]  WITH CHECK ADD  CONSTRAINT [CK_FactPPH_ValueStatus] CHECK  (([DataStatusKey]=(1) AND [MeasureValue] IS NOT NULL OR [DataStatusKey]<>(1) AND [MeasureValue] IS NULL))
GO

ALTER TABLE [dw].[FactPPH] CHECK CONSTRAINT [CK_FactPPH_ValueStatus]
GO

ALTER TABLE [dw].[FactWorkforce]  WITH CHECK ADD  CONSTRAINT [CK_FactWorkforce_PractitionerCount] CHECK  (([PractitionerCount]>=(0)))
GO

ALTER TABLE [dw].[FactWorkforce] CHECK CONSTRAINT [CK_FactWorkforce_PractitionerCount]
GO

ALTER TABLE [stg].[Medicare_Clean]  WITH CHECK ADD  CONSTRAINT [CK_Medicare_Clean_Year] CHECK  (([FinancialYearStart]>=(2017) AND [FinancialYearStart]<=(2024)))
GO

ALTER TABLE [stg].[Medicare_Clean] CHECK CONSTRAINT [CK_Medicare_Clean_Year]
GO

ALTER TABLE [stg].[PPH_Clean]  WITH CHECK ADD  CONSTRAINT [CK_PPH_Clean_FinancialYearStart] CHECK  (([FinancialYearStart]>=(2017) AND [FinancialYearStart]<=(2023)))
GO

ALTER TABLE [stg].[PPH_Clean] CHECK CONSTRAINT [CK_PPH_Clean_FinancialYearStart]
GO

ALTER TABLE [stg].[WorkforceGP]  WITH CHECK ADD  CONSTRAINT [CK_WorkforceGP_PractitionerCount] CHECK  (([PractitionerCount]>=(0)))
GO

ALTER TABLE [stg].[WorkforceGP] CHECK CONSTRAINT [CK_WorkforceGP_PractitionerCount]
GO
