--http://www.sqlskills.com/blogs/paul/sos_scheduler_yield-waits-and-the-lock_hash-spinlock/
--Check processor collisions spins
IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
    WHERE [name] = N'##TempSpinlockStats1')
    DROP TABLE [##TempSpinlockStats1];
SELECT * INTO [##TempSpinlockStats1]
FROM sys.dm_os_spinlock_stats
WHERE [collisions] > 0
ORDER BY [name];
WAITFOR DELAY '00:00:10';
IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
    WHERE [name] = N'##TempSpinlockStats2')
    DROP TABLE [##TempSpinlockStats2];
SELECT * INTO [##TempSpinlockStats2]
FROM sys.dm_os_spinlock_stats
WHERE [collisions] > 0
ORDER BY [name];

SELECT
    '***' AS [New],
    [ts2].[name] AS [Spinlock],
    [ts2].[collisions] AS [DiffCollisions],
    [ts2].[spins] AS [DiffSpins],
    [ts2].[spins_per_collision] AS [SpinsPerCollision],
    [ts2].[sleep_time] AS [DiffSleepTime],
    [ts2].[backoffs] AS [DiffBackoffs]
FROM [##TempSpinlockStats2] [ts2]
LEFT OUTER JOIN [##TempSpinlockStats1] [ts1]
    ON [ts2].[name] = [ts1].[name]
WHERE [ts1].[name] IS NULL
UNION
SELECT
    '' AS [New],
    [ts2].[name] AS [Spinlock],
    [ts2].[collisions] - [ts1].[collisions] AS [DiffCollisions],
    [ts2].[spins] - [ts1].[spins] AS [DiffSpins],
    CASE ([ts2].[spins] - [ts1].[spins]) WHEN 0 THEN 0
        ELSE ([ts2].[spins] - [ts1].[spins]) /
            ([ts2].[collisions] - [ts1].[collisions]) END
            AS [SpinsPerCollision],
    [ts2].[sleep_time] - [ts1].[sleep_time] AS [DiffSleepTime],
    [ts2].[backoffs] - [ts1].[backoffs] AS [DiffBackoffs]
FROM [##TempSpinlockStats2] [ts2]
LEFT OUTER JOIN [##TempSpinlockStats1] [ts1]
    ON [ts2].[name] = [ts1].[name]
WHERE [ts1].[name] IS NOT NULL
    AND [ts2].[collisions] - [ts1].[collisions] > 0
ORDER BY [New] DESC, [Spinlock] ASC;


--If you notice a two-digit number in runnable_tasks_count continuously for long time (not once in a while), you will know that there is CPU pressure.
SELECT scheduler_id, current_tasks_count, runnable_tasks_count, work_queue_count, pending_disk_io_count
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255;

SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2))
AS [%signal (cpu) waits],
CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS
NUMERIC(20,2)) AS [%resource waits]
FROM sys.dm_os_wait_stats WITH (NOLOCK) OPTION (RECOMPILE);
-- Signal Waits above 15-20% is usually a sign of CPU pressure

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

WITH [Waits] AS
    (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
        100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
        N'CLR_SEMAPHORE',    N'LAZYWRITER_SLEEP',
        N'RESOURCE_QUEUE',   N'SQLTRACE_BUFFER_FLUSH',
        N'SLEEP_TASK',       N'SLEEP_SYSTEMTASK',
        N'WAITFOR',          N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'CHECKPOINT_QUEUE', N'REQUEST_FOR_DEADLOCK_SEARCH',
        N'XE_TIMER_EVENT',   N'XE_DISPATCHER_JOIN',
        N'LOGMGR_QUEUE',     N'FT_IFTS_SCHEDULER_IDLE_WAIT',
        N'BROKER_TASK_STOP', N'CLR_MANUAL_EVENT',
        N'CLR_AUTO_EVENT',   N'DISPATCHER_QUEUE_SEMAPHORE',
        N'TRACEWRITE',       N'XE_DISPATCHER_WAIT',
        N'BROKER_TO_FLUSH',  N'BROKER_EVENTHANDLER',
        N'FT_IFTSHC_MUTEX',  N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'DIRTY_PAGE_POLL',  N'SP_SERVER_DIAGNOSTICS_SLEEP')
    )
SELECT
    [W1].[wait_type] AS [WaitType],
    CAST ([W1].[WaitS] AS DECIMAL(14, 2)) AS [Wait_S],
    CAST ([W1].[ResourceS] AS DECIMAL(14, 2)) AS [Resource_S],
    CAST ([W1].[SignalS] AS DECIMAL(14, 2)) AS [Signal_S],
    [W1].[WaitCount] AS [WaitCount],
    CAST ([W1].[Percentage] AS DECIMAL(4, 2)) AS [Percentage],
    CAST (([W1].[WaitS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgWait_S],
    CAST (([W1].[ResourceS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgRes_S],
    CAST (([W1].[SignalS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgSig_S]
FROM [Waits] AS [W1] INNER JOIN [Waits] AS [W2] ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum], [W1].[wait_type], [W1].[WaitS],
    [W1].[ResourceS], [W1].[SignalS], [W1].[WaitCount], [W1].[Percentage]
HAVING SUM ([W2].[Percentage]) - [W1].[Percentage] < 95;
--Wait events

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
deqp.query_plan,
der.plan_handle,
ecp.*
from sys.dm_exec_sessions des
LEFT JOIN sys.dm_exec_requests der
ON des.session_id = der.session_id
LEFT JOIN sys.dm_exec_connections dec
ON des.session_id = dec.session_id
JOIN SYS.DM_EXEC_CACHED_PLANS ecp
ON der.plan_handle=ecp.plan_handle
CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) dest
CROSS APPLY sys.dm_exec_query_plan(der.plan_handle) deqp
WHERE des.session_id <> @@SPID;
--Transactions on execution

SELECT TOP 50
SUBSTRING(eqt.TEXT,(
eqs.statement_start_offset/2) +1
,((CASE eqs.statement_end_offset
  WHEN -1 THEN DATALENGTH(eqt.TEXT)
  ELSE  eqs.statement_end_offset
  END - eqs.statement_start_offset)/2)+1)
,eqs.execution_count
,eqs.total_logical_reads
,eqs.last_logical_reads
,eqs.total_logical_writes
,eqs.last_logical_writes
,eqs.total_worker_time
,eqs.last_worker_time
,eqs.total_elapsed_time/1000000	AS Total_elapsed_time_Secs
,eqs.last_elapsed_time/1000000	AS Last_elapsed_time_Secs
,eqs.last_execution_time
,eqp.query_plan
FROM        sys.dm_exec_query_stats eqs
CROSS APPLY sys.dm_exec_sql_text(eqs.sql_handle) eqt
CROSS APPLY sys.dm_exec_query_plan(eqs.plan_handle) eqp
ORDER BY eqs.total_worker_time DESC
--Top 50 queries with high processor consumption
