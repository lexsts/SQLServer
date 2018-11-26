--Table/Index Size
--sp_spaceused SalesOrdDemo
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


--Check the statistics
--sp_autostats 'dbo.SalesOrdDemo' --last updated
--DBCC SHOW_STATISTICS ('dbo.SalesOrdDemo', idx_SalesOrdDemo_SalesOrderID); --with histogram
--EXEC sp_helpstats 'dbo.SalesOrdDemo', 'ALL'; --columns with statistics
SELECT t.name TableName, s.[name] StatName, STATS_DATE(t.object_id,s.[stats_id]) LastUpdated 
FROM sys.[stats] AS s
JOIN sys.[tables] AS t
    ON [s].[object_id] = [t].[object_id]
WHERE t.type = 'u'
and t.name='SalesOrdDemo'

--Check the number of changes made on a table since its last update statistics
SELECT DISTINCT
	OBJECT_NAME(SI.object_id) as Table_Name
	,SI.[name] AS Statistics_Name
	,STATS_DATE(SI.object_id, SI.index_id) AS Last_Stat_Update_Date
	,SSI.rowmodctr AS RowModCTR
	,SP.rows AS Total_Rows_In_Table
	,'UPDATE STATISTICS ['+SCHEMA_NAME(SO.schema_id)+'].[' 
		+ object_name(SI.object_id) + ']' 
			+ SPACE(2) + SI.[name] AS Update_Stats_Script
FROM sys.indexes AS SI (nolock) JOIN sys.objects AS SO (nolock) 
ON SI.object_id=SO.object_id
JOIN sys.sysindexes SSI (nolock)
ON SI.object_id=SSI.id
AND SI.index_id=SSI.indid 
JOIN sys.partitions AS SP
ON SI.object_id=SP.object_id	
WHERE SSI.rowmodctr>0
AND STATS_DATE(SI.object_id, SI.index_id) IS NOT NULL
AND SO.type='U' --Tabela de usuario
ORDER BY SSI.rowmodctr  DESC



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



		--ALTER INDEX PK_REGISTROS ON DBO.REGISTROS REBUILD
		--ALTER INDEX PK_REGISTROS ON DBO.REGISTROS REORGANIZE
		--UPDATE STATISTICS [dbo].[registros]
		--ALTER INDEX [PK_REGISTROS] ON [dbo].[REGISTROS] REBUILD PARTITION = 1
		--ALTER INDEX [PK_REGISTROS] ON [dbo].[REGISTROS] REBUILD PARTITION = 2

		--manually create stats
		--CREATE STATISTICS <<Statastics name>> ON
		--<<SCHEMA NAME>>.<<TABLE NAME>>(<<COLUMN NAME>>)
		--CREATE STATISTICS st_DueDate_SalesOrderHeader ON Sales.
		--SalesOrderHeader(DueDate)

		--update statistics for Sales.SalesOrderHeader Table
		--UPDATE STATISTICS Sales.SalesOrderHeader;

		--update statistics for st_DueDate_SalesOrderHeader stats
		--of Sales.SalesOrderHeader Table
		--UPDATE STATISTICS Sales.SalesOrderHeader st_DueDate_
		--SalesOrderHeader

		--update all statistics available in database
		--EXEC sp_updatestats

		--manually deleting stats
		--DROP STATISTICS
		--<<SCHEMA NAME>>.<<TABLE NAME>>.<<Statastics name>>
		--DROP STATISTICS Sales.SalesOrderHeader.st_DueDate_SalesOrderHeader


--Generate update statistics command for all databases
/*DECLARE @SQL VARCHAR(1000) 
DECLARE @DB sysname 
DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR 
   SELECT [name] 
   FROM master..sysdatabases
   WHERE [name] NOT IN ('model', 'tempdb')
   ORDER BY [name]    
OPEN curDB 
FETCH NEXT FROM curDB INTO @DB 
WHILE @@FETCH_STATUS = 0 
   BEGIN 
       SELECT @SQL = 'USE [' + @DB +']' + CHAR(13) + 'EXEC sp_updatestats' + CHAR(13) 
       PRINT @SQL 
	   PRINT 'GO'
       FETCH NEXT FROM curDB INTO @DB 
   END    
CLOSE curDB 
DEALLOCATE curDB*/

