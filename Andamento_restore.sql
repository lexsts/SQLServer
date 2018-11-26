SELECT command,
            s.text,
            start_time,
            percent_complete,
            CAST(((DATEDIFF(s,start_time,GetDate()))/3600) as varchar) + ' hour(s), '
                  + CAST((DATEDIFF(s,start_time,GetDate())%3600)/60 as varchar) + 'min, '
                  + CAST((DATEDIFF(s,start_time,GetDate())%60) as varchar) + ' sec' as running_time,
            CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
                  + CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
                  + CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go,
            dateadd(second,estimated_completion_time/1000, getdate()) as est_completion_time
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) s
WHERE r.command in ('RESTORE DATABASE', 'BACKUP DATABASE', 'RESTORE LOG', 'BACKUP LOG');



--Check thread on SO (KPID)
SELECT msp.spid, msp.kpid, msp.blocked, msp.loginame, des.host_name, des.program_name,des.status, command, s.text, 
percent_complete,	msp.login_time,des.last_request_start_time, r.status,r.wait_type,r.last_wait_type, r.total_elapsed_time,			
            CAST(((DATEDIFF(s,start_time,GetDate()))/3600) as varchar) + ' hour(s), '
                  + CAST((DATEDIFF(s,start_time,GetDate())%3600)/60 as varchar) + 'min, '
                  + CAST((DATEDIFF(s,start_time,GetDate())%60) as varchar) + ' sec' as running_time,
            CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
                  + CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
                  + CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go,
            dateadd(second,estimated_completion_time/1000, getdate()) as est_completion_time
FROM sys.dm_exec_requests r
JOIN master..sysprocesses msp
ON r.session_id=msp.spid
JOIN sys.dm_exec_sessions des
ON msp.spid=des.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) s


\\saoshappp36n2\K$\Data\Backup\Dados\CHIPSHOP\bkp_Chipshop.trn

RESTORE LOG CHIPSHOP
FROM DISK = '\\saoshappp36n2\K$\Data\Backup\Dados\CHIPSHOP\bkp_Chipshop.trn'
WITH NORECOVERY
go
