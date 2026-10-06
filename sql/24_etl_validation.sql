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
SELECT N'PPH' AS Dataset,
 (SELECT COUNT_BIG(*) FROM stg.vwPPH_Deduplicated) AS SourceRows,
 (SELECT COUNT_BIG(*) FROM dw.FactPPH) AS FactRows
UNION ALL SELECT N'Medicare',
 (SELECT COUNT_BIG(*) FROM stg.vwMedicare_Deduplicated),
 (SELECT COUNT_BIG(*) FROM dw.FactMedicareService)
UNION ALL SELECT N'SEIFA distribution',
 (SELECT COUNT_BIG(*) FROM stg.vwSEIFA_Distribution_Clean),
 (SELECT COUNT_BIG(*) FROM dw.FactSEIFADistribution)
UNION ALL SELECT N'SEIFA IRSD summary',
 (SELECT COUNT_BIG(*) FROM stg.vwSEIFA_IRSD_Summary_Clean),
 (SELECT COUNT_BIG(*) FROM dw.FactSEIFASA3Summary);
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
SELECT cy.CalendarYear,COUNT_BIG(*) AS WorkforceRows,SUM(CONVERT(bigint,f.PractitionerCount)) AS PractitionerTotal
FROM dw.FactWorkforce f JOIN dw.DimCalendarYear cy ON cy.CalendarYearKey=f.CalendarYearKey
GROUP BY cy.CalendarYear;
SELECT TOP (10) * FROM rpt.vwCareGapDashboardV2;

GO
