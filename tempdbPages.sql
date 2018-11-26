--Contention on Tempdb
Select session_id,
wait_type,
wait_duration_ms,
blocking_session_id,
resource_description,
      ResourceType = Case
When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 1 % 8088 = 0 Then 'Is PFS Page'
            When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 2 % 511232 = 0 Then 'Is GAM Page'
            When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 3 % 511232 = 0 Then 'Is SGAM Page'
            Else 'Is Not PFS, GAM, or SGAM page'
            End
From sys.dm_os_waiting_tasks
Where wait_type Like 'PAGE%LATCH_%'
And resource_description Like '2:%'
GO



--Tasks that are using TempDB
SELECT est.text, 
		tsu.session_id,
		tsu.database_id,
		der.start_time,*
FROM sys.dm_db_task_space_usage tsu
JOIN sys.dm_exec_requests der
on tsu.session_id=der.session_id
CROSS APPLY sys.dm_exec_sql_text (der.sql_handle) est



--Page allocation details
SELECT 
	session_id
	,database_id
	,user_objects_alloc_page_count
	,user_objects_dealloc_page_count
	,internal_objects_alloc_page_count
	,internal_objects_dealloc_page_count 
	FROM sys.dm_db_session_space_usage 
	WHERE internal_objects_alloc_page_count > 0
--WHERE session_id = @@SPID
GO



--Space utilization
SELECT 	
	DB_NAME(FSU.database_id) AS DatabaseName
	,MF.Name As LogicalFileName 
	,MF.physical_name AS PhysicalFilePath
	,ROUND(SUM(FSU.unallocated_extent_page_count)*8.0/1024,0) AS Free_Space_In_MB,	
	ROUND(SUM(COALESCE(FSU.version_store_reserved_page_count,0)  
		 + COALESCE(FSU.user_object_reserved_page_count,0)  
		 + COALESCE(FSU.internal_object_reserved_page_count,0)  
		 + COALESCE(FSU.mixed_extent_page_count,0))*8.0/1024,0) AS Used_Space_In_MB
FROM sys.dm_db_file_space_usage AS FSU
INNER JOIN sys.master_files AS MF
ON FSU.database_id = MF.database_id
	AND FSU.file_id = MF.file_id
GROUP BY FSU.database_id,FSU.file_id,MF.Name,MF.physical_name
GO


/*
Implementar o sinalizador de rastreamento -T1118 .

Observação Sinalizador de rastreamento -T1118 também está disponível e com suporte no Microsoft SQL Server 2005 e SQL Server 2008. No entanto, se você estiver executando o SQL Server 2005 ou SQL Server 2008, não é necessário aplicar qualquer hotfix.

Aumente o número de arquivos de dados tempdb a serem pelo menos igual ao número de processadores. Além disso, criar os arquivos com dimensionamento igual. Para obter mais informações, consulte a seção "Mais informação".

http://support.microsoft.com/kb/328551
*/



