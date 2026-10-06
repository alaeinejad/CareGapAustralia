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
-- Object inventory and row counts; empty tables are expected after schema installation.
SELECT s.name AS SchemaName,t.name AS TableName,SUM(p.rows) AS RowCount
FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN (0,1)
GROUP BY s.name,t.name ORDER BY s.name,t.name;
GO
-- Integrity check; no result rows indicate no reported constraint violations.
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
GO
-- Disabled or untrusted constraints require review.
SELECT name,is_disabled,is_not_trusted FROM sys.foreign_keys
WHERE is_disabled=1 OR is_not_trusted=1;
SELECT name,is_disabled,is_not_trusted FROM sys.check_constraints
WHERE is_disabled=1 OR is_not_trusted=1;
GO
