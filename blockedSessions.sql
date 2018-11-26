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


--Finding the command that caused blocking via sys.dm_exec_connections.
SELECT  ec.session_id ,
        ec.connect_time ,
        st.dbid AS DatabaseID ,
        st.objectid ,
        st.text
FROM    sys.dm_exec_connections ec
        CROSS APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) st
WHERE   session_id = 59;

--Querying the sys.dm_tran_locks DMV with the Spids
SELECT  request_session_id ,
        resource_type ,
        DB_NAME(resource_database_id) AS DatabaseName ,
        resource_associated_entity_id ,
        resource_description ,
        request_mode ,
        request_status
FROM    sys.dm_tran_locks AS dtl
WHERE   request_session_id IN ( 61, 59 )
        AND resource_type NOT IN ( 'DATABASE', 'METADATA' )



--See all sessions locked for one Spid
--exec sp_lock 52
