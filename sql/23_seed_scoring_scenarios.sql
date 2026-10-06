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
-- Four documented V1 sensitivity scenarios; baseline reporting V2 uses current views.

BEGIN TRY
    BEGIN TRANSACTION;
INSERT INTO dw.DimScoringScenario
(
    ScenarioCode,
    ScenarioName,
    ScenarioDescription,
    PPHWeight,
    GPServiceWeight,
    GPCoverageWeight,
    IRSDWeight,
    IsBaselineScenario
)
SELECT
    v.ScenarioCode,
    v.ScenarioName,
    v.ScenarioDescription,
    v.PPHWeight,
    v.GPServiceWeight,
    v.GPCoverageWeight,
    v.IRSDWeight,
    v.IsBaselineScenario
FROM
(
    VALUES
    (
        N'BALANCED_V1',
        N'Balanced V1',
        N'Balances preventable hospitalisations, GP utilisation and socio-economic disadvantage.',
        CAST(0.50 AS decimal(5,4)),
        CAST(0.20 AS decimal(5,4)),
        CAST(0.10 AS decimal(5,4)),
        CAST(0.20 AS decimal(5,4)),
        CAST(1 AS bit)
    ),
    (
        N'OUTCOME_FOCUSED',
        N'Outcome focused',
        N'Places greater emphasis on potentially preventable hospitalisation pressure.',
        CAST(0.65 AS decimal(5,4)),
        CAST(0.15 AS decimal(5,4)),
        CAST(0.05 AS decimal(5,4)),
        CAST(0.15 AS decimal(5,4)),
        CAST(0 AS bit)
    ),
    (
        N'ACCESS_FOCUSED',
        N'Primary-care access focused',
        N'Places greater emphasis on GP service intensity and population coverage.',
        CAST(0.40 AS decimal(5,4)),
        CAST(0.30 AS decimal(5,4)),
        CAST(0.20 AS decimal(5,4)),
        CAST(0.10 AS decimal(5,4)),
        CAST(0 AS bit)
    ),
    (
        N'EQUITY_FOCUSED',
        N'Equity focused',
        N'Places greater emphasis on socio-economic disadvantage.',
        CAST(0.40 AS decimal(5,4)),
        CAST(0.15 AS decimal(5,4)),
        CAST(0.10 AS decimal(5,4)),
        CAST(0.35 AS decimal(5,4)),
        CAST(0 AS bit)
    )
) AS v
(
    ScenarioCode,
    ScenarioName,
    ScenarioDescription,
    PPHWeight,
    GPServiceWeight,
    GPCoverageWeight,
    IRSDWeight,
    IsBaselineScenario
)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.DimScoringScenario AS d
    WHERE d.ScenarioCode = v.ScenarioCode
);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
