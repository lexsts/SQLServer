--Retrieving Index Fragmentation Details
--Retrieving Index Fragmentation Details
SELECT
	O.name AS ObjectName
	,I.name AS IndexName
	,I.type_desc AS IndexType
	,IPS.partition_number
	,IPS.index_level
	,IPS.avg_page_space_used_in_percent AS AverageSpaceUsedInPages
	,IPS.avg_fragmentation_in_percent AS AverageFragmentation
	,IPS.fragment_count AS FragmentCount
	,suggestedIndexOperation = CASE 
		WHEN IPS.avg_fragmentation_in_percent<=30 THEN 'REORGANIZE Index'
		ELSE 'REBUILD Index' END
	,suggestedIndexCommand = CASE 
		WHEN IPS.avg_fragmentation_in_percent<=30 THEN 'ALTER INDEX ' + I.name + ' ON ' + DB_NAME() + '..' + O.name + ' REORGANIZE;'
		ELSE 'ALTER INDEX ' + I.name + ' ON ' + DB_NAME() + '..' + O.name + ' REBUILD;' END
FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,'DETAILED') AS IPS
INNER JOIN sys.indexes AS I WITH (nolock)
ON IPS.object_id = I.object_id AND IPS.index_id = I.index_id
INNER JOIN sys.objects AS O WITH (nolock)
ON IPS.object_id = O.object_id 
WHERE IPS.avg_fragmentation_in_percent >= 0
--AND I.name='_dta_index_ProductDemo_c_5_999674609__K1'
AND O.name='SalesOrdDemo'
ORDER BY AverageFragmentation DESC

SELECT 
     SchemaName = s.name,
     TableName = t.name,
     IndexName = ind.name,
     IndexId = ind.index_id,
     ColumnId = ic.index_column_id,
     ColumnName = col.name,
     ind.*,
     ic.*,
     col.* 
FROM 
     sys.indexes ind 
INNER JOIN 
     sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
INNER JOIN 
     sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
INNER JOIN 
     sys.tables t ON ind.object_id = t.object_id 
INNER JOIN
	sys.schemas s ON t.schema_id=s.schema_id
WHERE 
	 --ind.name='PK_REGISTROS'
	 t.name='SalesOrdDemo'
ORDER BY t.name, ind.name, ind.index_id, ic.index_column_id 

--for gathering information of all indexes on specified table
SELECT
	sysOb.name as tableName
	,sysSch.name as schemaName
	,sysin.name as IndexName
	,func.partition_number
	,func.index_level
	,func.avg_fragmentation_in_percent
	,func.index_type_desc as IndexType
	,func.page_count
	,'ALTER INDEX ' + sysin.name + ' ON ' + sysSch.name + '.' + sysOb.name + ' REBUILD WITH (ONLINE=ON)'
	FROM
	sys.dm_db_index_physical_stats (DB_ID(),OBJECT_ID(N'SalesOrdDemo'),NULL, NULL, 'DETAILED') AS func
JOIN
   sys.indexes AS sysIn
ON
   func.object_id = sysIn.object_id AND func.index_id = sysIn.index_id
JOIN sys.objects AS sysOb
ON
	sysIn.object_id=sysOb.object_id
JOIN
	SYS.SCHEMAS AS sysSch
ON sysOb.schema_id=sysSch.schema_id
--Clustered Index's Index_id MUST be 1
--nonclustered Index should have Index_id>1
--with following WHERE clause, we are eliminating HEAP tables
WHERE sysIn.index_id>0

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
AND t.NAME IN ('SalesOrdDemo')
GROUP BY t.Name, s.Name, i.name, i.type_desc
ORDER BY s.Name, t.Name, i.name

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


		--ALTER INDEX PK_REGISTROS ON DBO.REGISTROS REBUILD
		--ALTER INDEX PK_REGISTROS ON DBO.REGISTROS REORGANIZE
		--UPDATE STATISTICS [dbo].[registros]
		--ALTER INDEX [PK_REGISTROS] ON [dbo].[REGISTROS] REBUILD PARTITION = 1
		--ALTER INDEX [PK_REGISTROS] ON [dbo].[REGISTROS] REBUILD PARTITION = 2

