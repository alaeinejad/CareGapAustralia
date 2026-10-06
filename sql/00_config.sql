/* CareGap Australia SQL-only GitHub package.
SSMS: enable Query > SQLCMD Mode. sqlcmd: run from this sql folder.
Edit DatabaseName and SourceRoot. DatabaseName must be unused for installation.
SourceRoot is a SERVER-accessible folder. Folder layout is documented below.
Source files, original Excel-to-CSV preparation, Power BI and DAX are not included.
Execution was not tested on SQL Server here. Static schema and dependency checks only.
Do not run the fresh-build workflow against your populated project database.
*/
:setvar DatabaseName "CareGapAustraliaDW_GitHubTest"
:setvar SourceRoot "C:\CareGapAustralia\Data"
