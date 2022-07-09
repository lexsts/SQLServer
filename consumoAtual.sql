--ALL SESSIONS
--DBCC FREEPROCCACHE
--DBCC FREEPROCCACHE (0x06000400FFDD9103409D20EA0100000001000000000000000000000000000000000000000000000000000000) --PLAN_HANDLE
/*CPU THREADS
select (select max_workers_count from sys.dm_os_sys_info) as 'TotalThreads',sum(active_Workers_count) as 'Currentthreads',(select max_workers_count from sys.dm_os_sys_info)-sum(active_Workers_count) as 'Availablethreads',sum(runnable_tasks_count) as 'WorkersWaitingfor_cpu',sum(work_queue_count) as 'Request_Waiting_for_threads' 
from  sys.dm_os_Schedulers where status='VISIBLE ONLINE'

DECLARE @OnlineCpuCount int
DECLARE @LogicalCpuCount int

SELECT @OnlineCpuCount = COUNT(*) FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE'
SELECT @LogicalCpuCount = cpu_count FROM sys.dm_os_sys_info 

SELECT @LogicalCpuCount AS 'ASSIGNED ONLINE CPU #', @OnlineCpuCount AS 'VISIBLE ONLINE CPU #',
   CASE 
     WHEN @OnlineCpuCount < @LogicalCpuCount 
     THEN 'You are not using all CPU assigned to O/S! If it is VM, review your VM configuration to make sure you are not maxout Socket'
     ELSE 'You are using all CPUs assigned to O/S. GOOD!' 
   END as 'CPU Usage Desc'
---------------------------

--COLETA LIMPA DO SQLSCOUT
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);
GO
*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT
    SPID                = er.session_id	
    ,BlkBy              = CASE WHEN lead_blocker = 1 THEN -1 ELSE er.blocking_session_id END
	,MAXDOP				= er.dop
    ,ElapsedMS          = er.total_elapsed_time
    ,CPU                = er.cpu_time
    ,IOReads            = er.logical_reads + er.reads
    ,IOWrites           = er.writes     
    ,Executions         = ec.execution_count  
    ,CommandType        = er.command         
    ,LastWaitType       = er.last_wait_type    
    ,ObjectName         = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid) 
	,SQLStatement       =
        SUBSTRING
        (
            qt.text,
            er.statement_start_offset/2,
            (CASE WHEN er.statement_end_offset = -1
                THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
                ELSE er.statement_end_offset
                END - er.statement_start_offset)/2
        )        	
    ,FULLStatement       = COALESCE(qt.text, BU.event_info)
    ,STATUS             = ses.STATUS
    ,[Login]            = ses.login_name
    ,Host               = ses.host_name
    ,DBName             = DB_Name(er.database_id)
    ,StartTime          = er.start_time
    ,Protocol           = con.net_transport
    ,transaction_isolation =
        CASE ses.transaction_isolation_level
            WHEN 0 THEN 'Unspecified'
            WHEN 1 THEN 'Read Uncommitted'
            WHEN 2 THEN 'Read Committed'
            WHEN 3 THEN 'Repeatable'
            WHEN 4 THEN 'Serializable'
            WHEN 5 THEN 'Snapshot'
        END
    ,ConnectionWrites   = con.num_writes
    ,ConnectionReads    = con.num_reads
    ,ClientAddress      = con.client_net_address
    ,Authentication     = con.auth_scheme
    ,DatetimeSnapshot   = GETDATE()
FROM sys.dm_exec_requests er
LEFT JOIN sys.dm_exec_sessions ses
ON ses.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections con
ON con.session_id = ses.session_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
OUTER APPLY 
(
    SELECT execution_count = MAX(cp.usecounts)
    FROM sys.dm_exec_cached_plans cp
    WHERE cp.plan_handle = er.plan_handle
) ec
OUTER APPLY
(
    SELECT
        lead_blocker = 1
    FROM master.dbo.sysprocesses sp
    WHERE sp.spid IN (SELECT blocked FROM master.dbo.sysprocesses)
    AND sp.blocked = 0
    AND sp.spid = er.session_id
) lb
OUTER APPLY sys.dm_exec_input_buffer(ses.session_id, NULL) BU
ORDER BY
    er.start_time

--Conversões implicitas
SELECT  DB_NAME(sql_text.[dbid]) AS DatabaseName,
sql_text.text AS [Query Text],
query_stats.execution_count AS [Execution Count], 
execution_plan.query_plan AS [Query Plan]
FROM sys.dm_exec_query_stats AS query_stats WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS sql_text 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS execution_plan
WHERE 
CAST(query_plan AS VARCHAR(MAX)) LIKE ('%CONVERT_IMPLICIT%')
AND 
DB_NAME(sql_text.[dbid])='WideWorldImporters'
AND 
CAST(query_plan AS VARCHAR(MAX)) NOT LIKE '%CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS sql_text%'

--Blocking
--Finding Blocking Information
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

SELECT  er.session_id ,
        host_name ,
        program_name ,
        original_login_name ,
        er.reads ,
        er.writes ,
        er.cpu_time ,
        wait_type ,
        wait_time ,
        wait_resource ,
        blocking_session_id ,
        st.text
FROM    sys.dm_exec_sessions es
        LEFT JOIN sys.dm_exec_requests er ON er.session_id = es.session_id
        OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE   blocking_session_id > 0
UNION
SELECT  es.session_id ,
        host_name ,
        program_name ,
        original_login_name ,
        es.reads ,
        es.writes ,
        es.cpu_time ,
        wait_type ,
        wait_time ,
        wait_resource ,
        blocking_session_id ,
        st.text
FROM    sys.dm_exec_sessions es
        LEFT JOIN sys.dm_exec_requests er ON er.session_id = es.session_id
        OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE   es.session_id IN ( SELECT   blocking_session_id
                           FROM     sys.dm_exec_requests
                           WHERE    blocking_session_id > 0 );



--Monitor database files for any 
--pending I/O requests.
SELECT 
	DB_NAME(VFS.database_id) AS DatabaseName
	,MF.name AS LogicalFileName
	,MF.physical_name AS PhysicalFileName
	,CASE MF.type
		WHEN 0 THEN 'Data File'
		WHEN 1 THEN 'Log File'		
	END AS FileType
	,PIOR.io_type AS InputOutputOperationType
	,PIOR.io_pending AS Is_Request_Pending	
	,PIOR.io_handle
	,PIOR.scheduler_address 
FROM sys.dm_io_pending_io_requests AS PIOR
INNER JOIN sys.dm_io_virtual_file_stats(NULL,NULL) AS VFS
ON PIOR.io_handle = VFS.file_handle 
INNER JOIN sys.master_files AS MF
ON VFS.database_id = MF.database_id AND VFS.file_id = MF.file_id
GO


--Detailed
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
--into #cargaAtual
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
go
use master
SELECT er.status,* FROM sys.dm_tran_active_transactions tat
INNER JOIN sys.dm_exec_requests er ON tat.transaction_id = er.transaction_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle)
go
SELECT * FROM sys.sysprocesses WHERE open_tran = 1
go

--WAIT RESOURCE
SELECT es.session_id, DB_NAME(er.database_id) AS [database_name],
OBJECT_NAME(qp.objectid, qp.dbid) AS [object_name], -- NULL if Ad-Hoc or Prepared statements
er.wait_type,
er.wait_resource,
er.status,
(SELECT CASE
WHEN pageid = 1 OR pageid % 8088 = 0 THEN 'Is_PFS_Page'
WHEN pageid = 2 OR pageid % 511232 = 0 THEN 'Is_GAM_Page'
WHEN pageid = 3 OR (pageid - 1) % 511232 = 0 THEN 'Is_SGAM_Page'
WHEN pageid IS NULL THEN NULL
ELSE 'Is Not PFS, GAM or SGAM page' END
FROM (SELECT CASE WHEN er.[wait_type] LIKE 'PAGE%LATCH%' AND er.[wait_resource] LIKE '%:%'
THEN CAST(RIGHT(er.[wait_resource], LEN(er.[wait_resource]) - CHARINDEX(':', er.[wait_resource], LEN(er.[wait_resource])-CHARINDEX(':', REVERSE(er.[wait_resource])))) AS INT)
ELSE NULL END AS pageid) AS latch_pageid
) AS wait_resource_type,er.last_wait_type,
er.wait_time AS wait_time_ms,
(SELECT qt.TEXT AS [text()] FROM sys.dm_exec_sql_text(er.sql_handle) AS qt
FOR XML PATH(''), TYPE) AS [running_batch],
(SELECT SUBSTRING(qt2.TEXT,
(CASE WHEN er.statement_start_offset = 0 THEN 0 ELSE er.statement_start_offset/2 END),
(CASE WHEN er.statement_end_offset = -1 THEN DATALENGTH(qt2.TEXT) ELSE er.statement_end_offset/2 END - (CASE WHEN er.statement_start_offset = 0 THEN 0 ELSE er.statement_start_offset/2 END))) AS [text()] FROM sys.dm_exec_sql_text(er.sql_handle) AS qt2
FOR XML PATH(''), TYPE) AS [running_statement],
qp.query_plan
FROM sys.dm_exec_requests er
LEFT OUTER JOIN sys.dm_exec_sessions es ON er.session_id = es.session_id
CROSS APPLY sys.dm_exec_query_plan (er.plan_handle) qp
WHERE er.session_id <> @@SPID AND es.is_user_process = 1
ORDER BY er.total_elapsed_time DESC, er.logical_reads DESC, [database_name], session_id
exec sp_who2

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
	,blocking_session_id AS RequestBlockedBy,
	R.plan_handle,
	ecp.*
FROM sys.dm_exec_requests AS R
INNER JOIN sys.dm_exec_sessions AS S
	ON R.session_id = S.session_id
JOIN SYS.DM_EXEC_CACHED_PLANS ecp
ON R.plan_handle=ecp.plan_handle
CROSS APPLY sys.dm_exec_sql_text(R.sql_handle) AS ST
CROSS APPLY sys.dm_exec_query_plan (R.plan_handle) AS QP
WHERE S.session_id <> @@SPID
ORDER BY TotalTimeElapsed DESC





--Monitoring currently executing cursors
--and listing them in the order of 
--most expensive to least expensive
SELECT 
	S.session_id
	,S.host_name AS ClientMachine
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
ORDER BY total_worker_time DESC
go
SELECT ss.sum_execution_count
	,t.TEXT
	,ss.sum_total_elapsed_time
	,ss.sum_total_worker_time
	,ss.sum_total_logical_reads
	,ss.sum_total_logical_writes
FROM (SELECT s.plan_handle
		,SUM(s.execution_count) sum_execution_count
		,SUM(s.total_elapsed_time) sum_total_elapsed_time
		,SUM(s.total_worker_time) sum_total_worker_time
		,SUM(s.total_logical_reads) sum_total_logical_reads
		,SUM(s.total_logical_writes) sum_total_logical_writes
		FROM sys.dm_exec_query_stats s
		GROUP BY s.plan_handle) AS ss
CROSS APPLY sys.dm_exec_sql_text(ss.plan_handle) t
ORDER BY sum_total_worker_time DESC
GO
--ORDER BY avg_physical_reads DESC 
--ORDER BY total_logical_reads DESC -- logical reads
--ORDER BY total_logical_writes DESC -- logical writes
--ORDER BY total_worker_time DESC -- CPU time



/*
--Perfmon to monitor CPU utilization on server:
- Processor/ %Privileged Time		percentage of time the processor spends on execution of Microsoft 
					Windows kernel commands such as core operating system activity 	
					and device drivers.
- Processor/ %User Time			percentage of time the processor spends on executing user 
					processes such as SQL Server. This includes I/O requests from SQL 
					Server
- Process (sqlservr.exe)/ %Processor Time	the sum of processor time on each processor for all 
						threads of the process

--Perfmon to monitor CPU utilization on instance:
- SQLServer:SQL Statistics/Auto-Param Attempts/sec
- SQLServer:SQL Statistics/Failed Auto-params/sec
- SQLServer:SQL Statistics/Batch Requests/sec
- SQLServer:SQL Statistics/SQL Compilations/sec
- SQLServer:SQL Statistics/SQL Re-Compilations/sec
- SQLServer:Plan Cache/Cache hit Ration


--Perfmon just to verify high number of recompilations
- SQLServer: SQL Statistics: SQL Compilations/Sec
- SQLServer: SQL Statistics: Auto-Param Attempts/Sec
- SQLServer: SQL Statistics: Failed Auto-Param/Sec

*/
