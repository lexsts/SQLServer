-- The following three queries return information about 
-- which objects belongs to which filegroup
--Space utilized by objects in each filegroup
SELECT f.name AS [FileGroup]	
	,SUM(a.total_pages)*8/1024 AS [ObjectsTotalSizeMB]
	,SUM(a.used_pages)*8/1024 AS [ObjectsUsedSizeMB]
	,SUM(a.data_pages)*8/1024 AS [ObjectsDataSizeMB]
FROM [sys].[filegroups] f
INNER JOIN sys.allocation_units a 
ON f.data_space_id=a.data_space_id
GROUP BY f.name
--Space configured in each Filegroup
SELECT 
	f.[name] AS [FileGroup]
	,d.[physical_name] AS [DatabaseFileName]
	,d.[size]*8/1024 AS [FileSizeMB]
	,d.[max_size]*8/1024 AS [FileMaxSizeMB]	
FROM [sys].[filegroups] f	
INNER JOIN [sys].[database_files] d
	ON f.[data_space_id] = d.[data_space_id]
GROUP BY f.[name],d.[physical_name],d.[size],d.[max_size]
ORDER BY f.[name],d.[physical_name] 


--Object's location
SELECT DS.name AS DataSpaceName 
      ,AU.type_desc AS AllocationDesc 
	  ,pa.partition_number AS [PartitionNumber]
      ,SCH.name AS SchemaName 
      ,OBJ.type_desc AS ObjectType       
      ,OBJ.name AS ObjectName 
      ,IDX.type_desc AS IndexType 
      ,IDX.name AS IndexName 
      ,AU.total_pages / 128 AS TotalSizeMB 
      ,AU.used_pages / 128 AS UsedSizeMB 
      ,AU.data_pages / 128 AS DataSizeMB 	  
FROM sys.data_spaces AS DS 
     INNER JOIN sys.allocation_units AS AU 
         ON DS.data_space_id = AU.data_space_id 
     INNER JOIN sys.partitions AS PA 
         ON (AU.type IN (1, 3)  
             AND AU.container_id = PA.hobt_id) 
            OR 
            (AU.type = 2 
             AND AU.container_id = PA.partition_id) 
     INNER JOIN sys.objects AS OBJ 
         ON PA.object_id = OBJ.object_id 
     INNER JOIN sys.schemas AS SCH 
         ON OBJ.schema_id = SCH.schema_id 
     LEFT JOIN sys.indexes AS IDX 
         ON PA.object_id = IDX.object_id 
            AND PA.index_id = IDX.index_id 
			where OBJ.name in ('REGISTROS')
ORDER BY DS.name 
        ,SCH.name 



--Table/Index Size
SELECT 
    s.Name AS SchemaName,
    t.NAME AS TableName,
	i.name AS IndexName,
	i.type_desc AS IndexType,
    SUM(p.rows) AS RowCounts,
    SUM(a.total_pages)*8/1024 AS TotalSpaceMB, 
    SUM(a.used_pages)*8/1024 AS UsedSpaceMB, 
    (SUM(a.total_pages)-SUM(a.used_pages))*8/1024 AS UnusedSpaceMB
FROM sys.tables t
INNER JOIN  sys.schemas s ON s.schema_id = t.schema_id
INNER JOIN  sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN  sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN  sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.NAME NOT LIKE 'dt%'    -- filter out system tables for diagramming
AND t.is_ms_shipped = 0
AND i.OBJECT_ID > 255 
AND t.NAME IN ('REGISTROS','ProductDemo')
GROUP BY t.Name, s.Name, i.name, i.type_desc
ORDER BY s.Name, t.Name, i.name
        ,OBJ.name 
		,IDX.name

--Check indexed view SIZE
SELECT 
	s.Name AS SchemaName,
    v.NAME AS ViewName,
    i.name AS IndexName,
	i.type_desc AS IndexType,
    SUM(p.rows) AS RowCounts,
    SUM(a.total_pages)*8/1024 AS TotalSpaceMB, 
    SUM(a.used_pages)*8/1024 AS UsedSpaceMB, 
    SUM(a.data_pages)*8/1024 AS DataSpaceMB
FROM sys.views v INNER JOIN sys.indexes i ON v.OBJECT_ID = i.object_id
INNER JOIN  sys.schemas s ON s.schema_id = v.schema_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE i.index_id = 1   -- clustered index, remove this to see all indexes
--AND v.Name = 'POView' --View name only, not 'schema.viewname'
GROUP BY s.Name,v.NAME,i.name,i.type_desc
ORDER BY s.Name, v.Name, i.name

