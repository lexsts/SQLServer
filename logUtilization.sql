--What is waiting log reuse:
--Log Backup: is necessary make a log backup
--Active_transaction: there is long-running or uncommitted transactions
SELECT db.[name] AS [Database Name], db.recovery_model_desc AS [Recovery Model],
db.log_reuse_wait_desc AS [Log Reuse Wait Description],
ls.cntr_value AS [Log Size (KB)], lu.cntr_value AS [Log Used (KB)],
CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) *
100 AS
[Log Used %], db.[compatibility_level] AS [DB Compatibility Level],
db.page_verify_option_desc AS [Page Verify Option], db.is_auto_create_stats_on,
db.is_auto_update_stats_on, db.is_auto_update_stats_async_on,
db.is_parameterization_forced,
db.snapshot_isolation_state_desc, db.is_read_committed_snapshot_on,
is_auto_shrink_on, is_auto_close_on
FROM sys.databases AS db WITH (NOLOCK)
INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)
ON db.name = lu.instance_name
INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK)
ON db.name = ls.instance_name
WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%'
AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
AND ls.cntr_value > 0 OPTION (RECOMPILE);




--Check internal space utilization
USE tempdb
GO

--Check if the table exists. If it does,
--dDrop it first.
IF OBJECT_ID('dbo.#tbl_DBLogSpaceUsage') IS NOT  NULL
BEGIN
	DROP TABLE dbo.#tbl_DBLogSpaceUsage
END
go
--Creating table to store the output 
--DBCC SQLPERF command
CREATE TABLE dbo.#tbl_DBLogSpaceUsage
(
	DatabaseName NVARCHAR(128)
	,LogSize NVARCHAR(25)
	,LogSpaceUsed NVARCHAR(25)
	,Status TINYINT
)
go
INSERT INTO dbo.#tbl_DBLogSpaceUsage
EXECUTE ('DBCC SQLPERF(LOGSPACE)')
go
--Retriving log space details for 
-- all databases.
SELECT 
	DatabaseName
	,LogSize
	,LogSpaceUsed
	,Status
FROM dbo.#tbl_DBLogSpaceUsage
GO

--Retriving log space details for 
-- a specific databases.
SELECT 
	DatabaseName
	,LogSize AS LogSizeInMB
	,LogSpaceUsed As LogspaceUsed_In_Percent
	,Status
FROM dbo.#tbl_DBLogSpaceUsage
WHERE DatabaseName = 'AdventureWorks2012'
GO


