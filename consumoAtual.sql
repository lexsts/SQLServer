--ALL SESSIONS
--DBCC FREEPROCCACHE
--DBCC FREEPROCCACHE (0x06000400FFDD9103409D20EA0100000001000000000000000000000000000000000000000000000000000000) --PLAN_HANDLE
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT
    SPID                = er.session_id
    ,BlkBy              = CASE WHEN lead_blocker = 1 THEN -1 ELSE er.blocking_session_id END
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
ORDER BY
    er.blocking_session_id DESC,
    er.logical_reads + er.reads DESC,
    er.session_id


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
