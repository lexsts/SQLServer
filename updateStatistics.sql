--Check columns and keys values
sp_helpstats 'scheme.tableName', 'ALL' --Shows statistics name and statistics keys
DBCC SHOW_STATISTICS('scheme.tableName',statisticsName) --Shows density, range of rows

SELECT object_id, OBJECT_NAME(object_id) AS TableName, name AS StatisticsName,auto_created
FROM sys.stats
where object_id=OBJECT_ID('Sales.SalesOrderHeader')
Order by object_id desc

--Verify if "autocreate/update option statistics" is set to true
SELECT is_auto_update_stats_async_on,is_auto_create_stats_on,is_auto_update_stats_on
FROM sys.databases WHERE name='databaseName'
--ALTER DATABASE AdventureWorks2012 SET AUTO_CREATE_STATISTICS ON --OFF
--ALTER DATABASE AdventureWorks2012 SET AUTO_UPDATE_STATISTICS ON --OFF
--ALTER DATABASE AdventureWorks2012 SET AUTO_UPDATE_STATISTICS_ASYNC ON --O
--CREATE STATISTICS st_DueDate_SalesOrderHeader ON Sales.SalesOrderHeader(DueDate)
--UPDATE STATISTICS Sales.SalesOrderHeader;
--DROP STATISTICS Sales.SalesOrderHeader.st_DueDate_SalesOrderHeader



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
WHERE STATS_DATE(SI.object_id, SI.index_id) IS NOT NULL
AND SSI.rowmodctr>0
--AND SO.type='U' --Tabela de usuario
--AND SO.NAME='IVAPONTREGIST'
AND SCHEMA_NAME(SO.schema_id) <> 'SYS'
ORDER BY SSI.rowmodctr  DESC




--UPDATE STATISTICS [dbo].[ordDemo]  --Na tabela inteira
--UPDATE STATISTICS [dbo].[DatabaseLog]  PK_DatabaseLog_DatabaseLogID   --Apenas no índice



--Generate update statistics command for all databases
DECLARE @SQL VARCHAR(1000) 
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
DEALLOCATE curDB



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

--When statistics are automaticaly colected
# The table size has gone from zero to more than zero rows
# The number of rows in the table, when the statistics were gathered, was 500 or less,
and the ColModCtr of the leading column of the statistics object has changed by
more than 500 since then
# The table had more than 500 rows when the statistics were gathered, and the
ColModCtr of the leading column of the statistics object has changed by more than
500 + 20% of the number of rows in the table when the statistics were gathered

