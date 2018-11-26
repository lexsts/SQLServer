-- 1.) Sys.Indexes catalog view to know the Fill Factor value –- of particular Index
--find fill factor value in index
SELECT 
	OBJECT_NAME(OBJECT_ID) AS TableName
	,Name as IndexName
	,Type_Desc
	,Fill_Factor
FROM 	sys.indexes
WHERE	--ommiting HEAP table by following condition therefore
	--it only displays clustered and nonclustered index details
	type_desc<>'HEAP'


--2.) Sys.Configurations catalog view to know the default Fill -- Factor value of serverfind default value of fill factor in -- database
SELECT 
	Description
	,Value_in_use
FROM 	sys.configurations
WHERE	Name ='fill factor (%)' 


--altering Index for FillFactor 80%
ALTER INDEX [idx_refno] ON [ordDemo]
REBUILD PARTITION=ALL WITH (FILLFACTOR= 80)
GO
-- If there is a need to change the default value of Fill 
-- Factor at server level, have a use of following TSQL
--setting default value server wide for Fill Factor

--turning on advanced configuration option
Sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO

--setting up default value for fill factor
sp_configure 'fill factor', 90
GO
RECONFIGURE
GO



--Check percentage of Changes and Fragmentation for a Fillfactor value
select  SCHEMA_NAME(B.schema_id) AS [Scheme]
		,B.name AS [TableName]
		,C.name AS IndexName,
		C.type_desc AS IndexType,
        A.user_scans,
        A.user_seeks,
        A.user_lookups, 
        A.user_updates, 
        D.rowcnt,
		(A.user_updates*100)/D.rowcnt AS [PercentChange],
        C.fill_factor
from sys.dm_db_index_usage_stats A
INNER JOIN sys.objects B ON A.object_id = B.object_id
INNER JOIN sys.indexes C ON C.object_id = B.object_id AND C.index_id = A.index_id
INNER JOIN sys.sysindexes D ON D.id = B.object_id AND D.indid = A.index_id
WHERE B.name in ('REGISTROS')

SELECT i.name,
       i.type_desc,
	   ps.partition_number,
	   ps.index_level,
       ps.avg_fragmentation_in_percent,
       ps.page_count,
       ps.record_count
FROM   sys.indexes i INNER JOIN sys.dm_db_index_physical_stats(db_id(), object_id('REGISTROS'), DEFAULT, DEFAULT, 'DETAILED') ps
       ON (
            i.object_id = ps.object_id AND
            i.index_id = ps.index_id
          )


SELECT i.name                    AS index_name,
       i.type_desc               AS type_desc,
       os.leaf_insert_count,
       os.leaf_delete_count,
       os.leaf_update_count,
       os.nonleaf_insert_count,
       os.nonleaf_delete_count,
       os.nonleaf_update_count
FROM   sys.indexes i INNER JOIN sys.dm_db_index_operational_stats (db_id(), DEFAULT, DEFAULT, DEFAULT) os
       ON (
            i.object_id = os.object_id AND
            i.index_id = os.index_id
           ) INNER JOIN sys.objects o
        ON (i.object_id = o.object_id)
WHERE   o.is_ms_shipped = 0 AND
        o.name = 'REGISTROS'
ORDER BY
        o.name,
        i.index_id


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



		--ALTER INDEX PK_REGISTROS ON DBO.REGISTROS REBUILD
		--ALTER INDEX PK_REGISTROS ON DBO.REGISTROS REORGANIZE
		--UPDATE STATISTICS [dbo].[registros]

--http://www.sqlskills.com/blogs/kimberly/database-maintenance-best-practices-part-ii-setting-fillfactor/
--http://db-berater.blogspot.de/2013/06/fillfactor-vor-und-nachteile.html

