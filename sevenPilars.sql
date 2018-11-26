--LOAD-------------------------------------------------------------------------
--insert into #cargaAtual
SELECT
des.session_id ,
des.status ,
des.login_name ,
des.[HOST_NAME] ,
der.blocking_session_id ,
DB_NAME(der.database_id) AS database_name ,
der.command ,
des.cpu_time ,
des.reads ,
des.writes ,
dec.last_write ,
des.[program_name] ,
der.wait_type ,
der.wait_time ,
der.last_wait_type ,
der.wait_resource ,
CASE des.transaction_isolation_level
WHEN 0 THEN 'Unspecified'
WHEN 1 THEN 'ReadUncommitted'
WHEN 2 THEN 'ReadCommitted'
WHEN 3 THEN 'Repeatable'
WHEN 4 THEN 'Serializable'
WHEN 5 THEN 'Snapshot'
END AS transaction_isolation_level ,
OBJECT_NAME(dest.objectid, der.database_id) AS OBJECT_NAME ,
SUBSTRING(dest.text, der.statement_start_offset / 2,
( CASE WHEN der.statement_end_offset = -1
THEN DATALENGTH(dest.text)
ELSE der.statement_end_offset
END - der.statement_start_offset ) / 2)
AS [executing statement] ,
deqp.query_plan
--into #cargaAtual
from sys.dm_exec_sessions des
LEFT JOIN sys.dm_exec_requests der
ON des.session_id = der.session_id
LEFT JOIN sys.dm_exec_connections dec
ON des.session_id = dec.session_id
CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) dest
CROSS APPLY sys.dm_exec_query_plan(der.plan_handle) deqp

WHERE des.session_id <> @@SPID;

--select * from #cargaAtual

--Monitoring currently executing queries
--and listing them in the order of 
--most resource-consuming to 
--least resource-consuming
SELECT	
	S.session_id		
	,DB_NAME(R.database_id) AS DatabaseName
	,S.original_login_name AS LoginName
	,S.host_name AS ClientMachine
	,S.program_name AS ApplicationName
	,R.start_time AS RequestStartTime	
	,ST.text AS SQLQuery
	,QP.query_plan AS ExecutionPlan
	,R.cpu_time AS CPUTime
	,R.total_elapsed_time AS TotalTimeElapsed	
	,R.open_transaction_count AS TotalTransactionsOpened
	,R.reads
	,R.logical_reads
	,R.writes AS TotalWrites	
	,CASE
		WHEN R.wait_type IS NULL THEN 'Request Not Blocked'
		ELSE 'Request Blocked'
	END AS QueryBlockInfo
	,blocking_session_id AS RequestBlockedBy	
FROM sys.dm_exec_requests AS R
INNER JOIN sys.dm_exec_sessions AS S
	ON R.session_id = S.session_id
CROSS APPLY sys.dm_exec_sql_text(R.sql_handle) AS ST
CROSS APPLY sys.dm_exec_query_plan (R.plan_handle) AS QP

WHERE S.session_id <> @@SPID
ORDER BY TotalTimeElapsed DESC
GO



--Monitoring currently executing cursors
--and listing them in the order of 
--most expensive to least expensive
SELECT 
	S.host_name AS ClientMachine
	,S.program_name AS ApplicationName
	,S.original_login_name AS LoginName
	,C.name AS CursorName
	,C.properties AS CursorOptions
	,C.creation_time AS CursorCreatinTime
	,ST.text AS SQLQuery
	,C.is_open AS IsCursorOpen
	,C.worker_time/1000 AS DurationInMiliSeconds
	,C.reads AS NumberOfReads
	,C.writes AS NumberOfWrites
FROM sys.dm_exec_cursors(0) AS C
INNER JOIN sys.dm_exec_sessions AS S
		ON C.session_id = S.session_id
CROSS APPLY sys.dm_exec_sql_text(C.sql_handle) AS ST
ORDER BY DurationInMiliSeconds DESC
GO


--Blocks
SELECT 
	R.session_id AS BlockedSessionID
	,S.session_id AS BlockingSessionID
	,Q1.text AS BlockedSession_TSQL
	,Q2.text AS BlockingSession_TSQL
	,S.original_login_name AS BlockingSession_LoginName
	,S.program_name AS BlockingSession_ApplicationName
	,S.host_name AS BlockingSession_HostName
	,C1.connect_time
	,C1.most_recent_sql_handle AS BlockedSession_SQLHandle
	,C2.most_recent_sql_handle AS BlockingSession_SQLHandle	
FROM sys.dm_exec_requests AS R
INNER JOIN sys.dm_exec_sessions AS S
ON R.blocking_session_id  = S.session_id
INNER JOIN sys.dm_exec_connections AS C1
ON R.session_id = C1.most_recent_session_id
INNER JOIN sys.dm_exec_connections AS C2
ON S.session_id = C2.most_recent_session_id
CROSS APPLY sys.dm_exec_sql_text (C1.most_recent_sql_handle) AS Q1
CROSS APPLY sys.dm_exec_sql_text (C2.most_recent_sql_handle) AS Q2;

--MEMORY-------------------------------------------------------------------------
-- Get information on location, time and size of any memory dumps from SQL Server
SELECT [filename], creation_time, size_in_bytes
FROM sys.dm_server_memory_dumps WITH (NOLOCK) OPTION (RECOMPILE);
-- This will not return any rows if you have
-- not had any memory dumps (which is a good thing)


-- Get total buffer usage by database for current instance
SELECT DB_NAME(database_id) AS [Database Name],
COUNT(*) * 8/1024.0 AS [Cached Size (MB)]
FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
WHERE database_id > 4 -- system databases
AND database_id <> 32767 -- ResourceDB
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC OPTION (RECOMPILE);
-- Tells you how much memory (in the buffer pool)
-- is being used by each database on the instance
--To freed up the memory we can use the below script together.
--DBCC FREESYSTEMCACHE ('ALL') WITH MARK_IN_USE_FOR_REMOVAL;
--DBCC FREESESSIONCACHE WITH NO_INFOMSGS;
--GO
--DBCC DROPCLEANBUFFERS
--DBCC FREEPROCCACHE;


-- Good basic information about OS memory amounts and state
SELECT total_physical_memory_kb, available_physical_memory_kb,
total_page_file_kb, available_page_file_kb,
system_memory_state_desc
FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);
-- You want to see "Available physical memory is high"
-- This indicates that you are not under external memory pressure


-- SQL Server Process Address space info
--(shows whether locked pages is enabled, among other things)
SELECT physical_memory_in_use_kb,locked_page_allocations_kb,
page_fault_count, memory_utilization_percentage,
available_commit_limit_kb, process_physical_memory_low,
process_virtual_memory_low
FROM sys.dm_os_process_memory WITH (NOLOCK) OPTION (RECOMPILE);
-- You want to see 0 for process_physical_memory_low
-- You want to see 0 for process_virtual_memory_low
-- This indicates that you are not under internal memory pressure


-- Page Life Expectancy (PLE) value for default instance
SELECT cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Buffer Manager%' -- Handles named instances
AND counter_name = N'Page life expectancy' OPTION (RECOMPILE);
-- PLE is one way to measure memory pressure.
-- Higher PLE is better. Watch the trend, not the absolute value.

-- Memory Grants Outstanding value for default instance
SELECT cntr_value AS [Memory Grants Outstanding]
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Memory Manager%' -- Handles named instances
AND counter_name = N'Memory Grants Outstanding' OPTION (RECOMPILE);
-- Memory Grants Outstanding above zero
-- for a sustained period is a secondary indicator of memory pressure

-- Memory Grants Pending value for default instance
SELECT cntr_value AS [Memory Grants Pending]
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Memory Manager%' -- Handles named instances
AND counter_name = N'Memory Grants Pending' OPTION (RECOMPILE);
-- Memory Grants Pending above zero
-- for a sustained period is an extremely strong indicator of memory pressure

-- Memory Clerk Usage for instance
-- Look for high value for CACHESTORE_SQLCP (Ad-hoc query plans)
SELECT TOP(10) [type] AS [Memory Clerk Type],
SUM(pages_kb) AS [SPA Mem, Kb]
FROM sys.dm_os_memory_clerks WITH (NOLOCK)
GROUP BY [type]
ORDER BY SUM(pages_kb) DESC OPTION (RECOMPILE);
--CACHESTORE_SQLCP SQL Plans
--These are cached SQL statements or batches that
--aren't in stored procedures, functions and triggers
--
--CACHESTORE_OBJCP Object Plans
--These are compiled plans for
--stored procedures, functions and triggers
--
--CACHESTORE_PHDR Algebrizer Trees
--An algebrizer tree is the parsed SQL text
--that resolves the table and column names


--CPU-------------------------------------------------------------------------
-- Signal Waits for instance
SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2))
AS [%signal (cpu) waits],
CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS
NUMERIC(20,2)) AS [%resource waits]
FROM sys.dm_os_wait_stats WITH (NOLOCK) OPTION (RECOMPILE);
-- Signal Waits above 15-20% is usually a sign of CPU pressure

-- Get CPU utilization by database
WITH DB_CPU_Stats
AS
(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName],
SUM(total_worker_time) AS [CPU_Time_Ms]
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID]
FROM sys.dm_exec_plan_attributes(qs.plan_handle)
WHERE attribute = N'dbid') AS F_DB
GROUP BY DatabaseID)
SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
DatabaseName, [CPU_Time_Ms],
CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms])
OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
FROM DB_CPU_Stats
WHERE DatabaseID > 4 -- system databases
AND DatabaseID <> 32767 -- ResourceDB
ORDER BY row_num OPTION (RECOMPILE);
-- Helps determine which database is
-- using the most CPU resources on the instance

-- Get CPU Utilization History for last 256 minutes (in one minute intervals)
-- This version works with SQL Server 2008 and above
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)
FROM sys.dm_os_sys_info WITH (NOLOCK));
SELECT TOP(256) SQLProcessUtilization AS [SQL Server Process CPU Utilization],
SystemIdle AS [System Idle Process],
100 - SystemIdle - SQLProcessUtilization
AS [Other Process CPU Utilization],
DATEADD(ms, -1 * (@ts_now - [timestamp]),
GETDATE()) AS [Event Time]
FROM (SELECT record.value('(./Record/@id)[1]', 'int') AS record_id,
record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int')
AS[SystemIdle],record.value('(./Record/SchedulerMonitorEvent/SystemHealth/
ProcessUtilization)[1]','int')
AS [SQLProcessUtilization], [timestamp]
FROM (SELECT [timestamp], CONVERT(xml, record) AS [record]
FROM sys.dm_os_ring_buffers WITH (NOLOCK)
WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
AND record LIKE N'%<SystemHealth>%') AS x
) AS y
ORDER BY record_id DESC OPTION (RECOMPILE);
-- Look at the trend over the entire period.
-- Also look at high sustained Other Process CPU Utilization values



--IO-------------------------------------------------------------------------
-- Calculates average stalls per read, per write,
-- and per total input/output for each database file.
SELECT DB_NAME(fs.database_id) AS [Database Name], mf.physical_name,
io_stall_read_ms, num_of_reads,
CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS
[avg_read_stall_ms],io_stall_write_ms,
num_of_writes,CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS
[avg_write_stall_ms],
io_stall_read_ms + io_stall_write_ms AS [io_stalls], num_of_reads + num_of_writes
AS [total_io],
CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS
NUMERIC(10,1))
AS [avg_io_stall_ms]
FROM sys.dm_io_virtual_file_stats(null,null) AS fs
INNER JOIN sys.master_files AS mf WITH (NOLOCK)
ON fs.database_id = mf.database_id
AND fs.[file_id] = mf.[file_id]
ORDER BY avg_io_stall_ms DESC OPTION (RECOMPILE);
-- Helps determine which database files on
-- the entire instance have the most I/O bottlenecks



--WAITS-------------------------------------------------------------------------
-- Isolate top waits for server instance since last restart or statistics clear
WITH Waits AS
(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s,
100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
FROM sys.dm_os_wait_stats WITH (NOLOCK)
WHERE wait_type NOT IN (N'CLR_SEMAPHORE',N'LAZYWRITER_SLEEP',N'RESOURCE_QUEUE',
N'SLEEP_TASK',N'SLEEP_SYSTEMTASK',N'SQLTRACE_BUFFER_FLUSH',N'WAITFOR',
N'LOGMGR_QUEUE',N'CHECKPOINT_QUEUE', N'REQUEST_FOR_DEADLOCK_SEARCH',
N'XE_TIMER_EVENT',N'BROKER_TO_FLUSH',N'BROKER_TASK_STOP',N'CLR_MANUAL_EVENT',
N'CLR_AUTO_EVENT',N'DISPATCHER_QUEUE_SEMAPHORE', N'FT_IFTS_SCHEDULER_IDLE_WAIT',
N'XE_DISPATCHER_WAIT', N'XE_DISPATCHER_JOIN', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
N'ONDEMAND_TASK_QUEUE', N'BROKER_EVENTHANDLER', N'SLEEP_BPOOL_FLUSH',
N'DIRTY_PAGE_POLL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
N'SP_SERVER_DIAGNOSTICS_SLEEP'))
SELECT W1.wait_type,
CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 99 OPTION (RECOMPILE); -- percentage threshold
-- Clear Wait Stats
-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);



--PLAN CACHE-------------------------------------------------------------------------
-- Find single-use, ad-hoc queries that are bloating the plan cache
SELECT TOP(20) [text] AS [QueryText], cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE cp.cacheobjtype = N'Compiled Plan'
AND cp.objtype = N'Adhoc'
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC OPTION (RECOMPILE);
--Gives you the text and size of single-use ad-hoc queries that
--waste space in the plan cache
--Enabling 'optimize for ad hoc workloads' for the instance
--can help (SQL Server 2008 and above only)
--Enabling forced parameterization for the database can help, but test first!

-- Top cached queries by Execution Count (SQL Server 2012)
SELECT qs.execution_count, qs.total_rows, qs.last_rows, qs.min_rows, qs.max_rows,
qs.last_elapsed_time, qs.min_elapsed_time, qs.max_elapsed_time,
SUBSTRING(qt.TEXT,qs.statement_start_offset/2 +1,
(CASE WHEN qs.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(MAX), qt.TEXT)) * 2
ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
AS query_text
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY qs.execution_count DESC OPTION (RECOMPILE);
-- Uses several new rows returned columns
-- to help troubleshoot performance problems


--Execution Plans on cache
--DBCC FREEPROCCACHE(plan_handle)
--DBCC FREEPROCINDB(db_id)
SELECT TOP ( 10 )
        SUBSTRING(ST.text, ( QS.statement_start_offset / 2 ) + 1,
                  ( ( CASE statement_end_offset
                        WHEN -1 THEN DATALENGTH(st.text)
                        ELSE QS.statement_end_offset
                      END - QS.statement_start_offset ) / 2 ) + 1) AS statement_text ,
        execution_count ,
        total_worker_time / 1000 AS total_worker_time_ms ,
        ( total_worker_time / 1000 ) / execution_count AS avg_worker_time_ms ,
        total_elapsed_time / 1000 AS total_elapsed_time_ms ,
        ( total_elapsed_time / 1000 ) / execution_count AS avg_elapsed_time_ms ,
	total_logical_reads ,
	total_logical_reads / execution_count AS avg_logical_reads ,
        total_logical_writes / execution_count AS avg_logical_writes ,
        total_physical_reads / execution_count AS avg_physical_reads ,
	last_rows,
	min_rows,
	max_rows,
	last_execution_time,
        qp.query_plan
FROM    sys.dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY total_worker_time DESC;
--ORDER BY avg_physical_reads DESC 
--ORDER BY total_logical_reads DESC -- logical reads
--ORDER BY total_logical_writes DESC -- logical writes
--ORDER BY total_worker_time DESC -- CPU time




/*
-- Top Cached SPs on specific database (SQL Server 2012)
SELECT TOP(250) p.name AS [SP Name], qs.execution_count,
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0)
AS [Calls/Second],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
qs.total_worker_time AS [TotalWorkerTime],qs.total_elapsed_time,
qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
qs.cached_time
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.execution_count DESC OPTION (RECOMPILE);
-- Tells you which cached stored procedures are called the most often
-- This helps you characterize and baseline your workload

SELECT TOP(250) p.name AS [SP Name], qs.execution_count,
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0)
AS [Calls/Second],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
qs.total_worker_time AS [TotalWorkerTime],qs.total_elapsed_time,
qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
qs.cached_time
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY avg_elapsed_time DESC OPTION (RECOMPILE);
-- This helps you find long-running cached stored procedures that
-- may be easy to optimize with standard query tuning techniques

SELECT TOP(250) p.name AS [SP Name], qs.execution_count,
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0)
AS [Calls/Second],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
qs.total_worker_time AS [TotalWorkerTime],qs.total_elapsed_time,
qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
qs.cached_time
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE);
-- This helps you find the most expensive cached
-- stored procedures from a CPU perspective
-- You should look at this if you see signs of CPU pressure

SELECT TOP(250) p.name AS [SP Name], qs.execution_count,
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0)
AS [Calls/Second],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
qs.total_worker_time AS [TotalWorkerTime],qs.total_elapsed_time,
qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
qs.cached_time
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_logical_reads DESC OPTION (RECOMPILE);
-- This helps you find the most expensive cached
-- stored procedures from a memory perspective
-- You should look at this if you see signs of memory pressure
*/


--PERFORMANCE MONITOR-------------------------------------------------------------------------
--Return all counters related to current instance
SELECT * FROM SYS.DM_OS_PERFORMANCE_COUNTERS
WHERE OBJECT_NAME LIKE '%' + @@SERVICENAME + '%'


