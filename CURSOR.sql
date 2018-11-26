DECLARE @NOME NVARCHAR(50)
DECLARE BASES_CURSOR CURSOR FOR 
SELECT NAME FROM SYS.DATABASES WHERE NAME NOT IN ('MASTER','MSDB','TEMPDB','MODEL')
OPEN BASES_CURSOR
FETCH NEXT FROM BASES_CURSOR INTO @NOME
WHILE @@FETCH_STATUS=0
BEGIN
SELECT 'ALTER DATABASE ' + @NOME + ' SET COMPATIBILITY_lEVEL=110'
FETCH NEXT FROM BASES_CURSOR INTO @NOME
END
CLOSE BASES_CURSOR
DEALLOCATE BASES_CURSOR


--Fechar cursor
IF (SELECT CURSOR_STATUS('global','BASES_CURSOR')) >= -4
 BEGIN
  IF (SELECT CURSOR_STATUS('global','BASES_CURSOR')) > -4
   BEGIN
    CLOSE BASES_CURSOR
   END
    DEALLOCATE BASES_CURSOR
END


--cursor aberto
SELECT  f.is_open, f.*
FROM    sys.dm_exec_cursors(0) f
WHERE   f.name = 'BASES_CURSOR'

--Cursor aberto
SELECT c.session_id
,c.cursor_id
,c.properties
,c.creation_time
,c.is_open
,c.fetch_status
,c.dormant_duration
,s.login_time
,t.text
FROM
sys.dm_exec_cursors (0) c
JOIN sys.dm_exec_sessions s
ON c.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(c.sql_handle) t

--Cursor gerando lock
SELECT OBJECT_NAME(P.object_id) AS TableName
,L.resource_type
,L.resource_description
,L.request_session_id
,L.request_mode
,L.request_type
,L.request_status
,L.request_reference_count
,L.request_lifetime
,L.request_owner_type
,s.transaction_isolation_level
,s.login_name
,s.login_time
,s.last_request_start_time
,s.last_request_end_time
,s.status
,s.program_name
,s.login_name
,s.nt_user_name
--,c.connect_time
--,c.last_read
--,c.last_write
--,t.text
FROM
sys.dm_tran_locks L
JOIN sys.partitions P
ON L.resource_associated_entity_id = P.hobt_id
JOIN sys.dm_exec_sessions s
ON L.request_session_id = s.session_id
--JOIN sys.dm_exec_connections c
--ON s.session_id = c.most_recent_session_id
--CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
WHERE
L.request_owner_type = 'CURSOR'
ORDER
BY L.request_session_id

