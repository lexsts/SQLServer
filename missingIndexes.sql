--finding missing Index
SELECT
      avg_total_user_cost * avg_user_impact * (user_seeks + user_scans)/100.0 AS PossibleImprovement
      ,GS.avg_user_impact As ExpectedPerformanceImprovement
      ,last_user_seek
      ,last_user_scan
      ,D.equality_columns
      ,D.inequality_columns
      ,D.included_columns 
      ,statement AS Object
      ,'CREATE INDEX [IDX_' + CONVERT(VARCHAR,GS.Group_Handle) + '_' + CONVERT(VARCHAR,D.Index_Handle) + '_'
      + REPLACE(REPLACE(REPLACE([statement],']',''),'[',''),'.','') + ']'
      +' ON '
      + [statement]
      + ' (' + ISNULL (equality_columns,'')
    + CASE WHEN equality_columns IS NOT NULL AND inequality_columns IS NOT NULL THEN ',' ELSE '' END
    + ISNULL (inequality_columns, '')
    + ')'
    + ISNULL (' INCLUDE (' + included_columns + ')', '')
      AS Create_Index_Syntax
FROM sys.dm_db_missing_index_groups AS G
INNER JOIN sys.dm_db_missing_index_group_stats AS GS
ON GS.group_handle = G.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS D
ON G.index_handle = D.index_handle
Order By PossibleImprovement DESC
GO



--Identifying missing indexes based on query cost benefit.
SELECT  migs.avg_total_user_cost * ( migs.avg_user_impact / 100.0 )
        * ( migs.user_seeks + migs.user_scans ) AS improvement_measure ,
        'CREATE INDEX [missing_index_'
        + CONVERT (VARCHAR, mig.index_group_handle) + '_'
        + CONVERT (VARCHAR, mid.index_handle) + '_'
        + LEFT(PARSENAME(mid.statement, 1), 32) + ']' + ' ON ' + mid.statement
        + ' (' + ISNULL(mid.equality_columns, '')
        + CASE WHEN mid.equality_columns IS NOT NULL
                    AND mid.inequality_columns IS NOT NULL THEN ','
               ELSE ''
          END + ISNULL(mid.inequality_columns, '') + ')' + ISNULL(' INCLUDE ('
                                                              + mid.included_columns
                                                              + ')', '') AS create_index_statement ,
        migs.* ,
        mid.database_id ,
        mid.[object_id]
FROM    sys.dm_db_missing_index_groups mig
        INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE   migs.avg_total_user_cost * ( migs.avg_user_impact / 100.0 )
        * ( migs.user_seeks + migs.user_scans ) > 10
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * ( migs.user_seeks + migs.user_scans ) DESC
GO

--Identifying single-column, non-indexed FOREIGN KEYs.
SELECT  fk.name AS CONSTRAINT_NAME ,
        s.name AS SCHEMA_NAME ,
        o.name AS TABLE_NAME ,
        fkc_c.name AS CONSTRAINT_COLUMN_NAME
FROM    sys.foreign_keys AS fk
        JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
        JOIN sys.columns AS fkc_c ON fkc.parent_object_id = fkc_c.object_id
                                     AND fkc.parent_column_id = fkc_c.column_id
        LEFT JOIN sys.index_columns ic
        JOIN sys.columns AS c ON ic.object_id = c.object_id
                                 AND ic.column_id = c.column_id ON fkc.parent_object_id = ic.object_id
                                                              AND fkc.parent_column_id = ic.column_id
        JOIN sys.objects AS o ON o.object_id = fk.parent_object_id
        JOIN sys.schemas AS s ON o.schema_id = s.schema_id
WHERE   c.name IS NULL
GO


--Parsing missing index information out of XML showplans
WITH XMLNAMESPACES
(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT  MissingIndexNode.value('(MissingIndexGroup/@Impact)[1]', 'float') AS impact ,
        OBJECT_NAME(sub.objectid, sub.dbid) AS calling_object_name ,
        MissingIndexNode.value('(MissingIndexGroup/MissingIndex/@Database)[1]',
                               'VARCHAR(128)') + '.'
        + MissingIndexNode.value('(MissingIndexGroup/MissingIndex/@Schema)[1]',
                                 'VARCHAR(128)') + '.'
        + MissingIndexNode.value('(MissingIndexGroup/MissingIndex/@Table)[1]',
                                 'VARCHAR(128)') AS table_name ,
        STUFF(( SELECT  ',' + c.value('(@Name)[1]', 'VARCHAR(128)')
                FROM    MissingIndexNode.nodes('MissingIndexGroup/MissingIndex/
ColumnGroup[@Usage="EQUALITY"]/Column') AS t ( c )
              FOR
                XML PATH('')
              ), 1, 1, '') AS equality_columns ,
        STUFF(( SELECT  ',' + c.value('(@Name)[1]', 'VARCHAR(128)')
                FROM    MissingIndexNode.nodes('MissingIndexGroup/MissingIndex/
ColumnGroup[@Usage="INEQUALITY"]/Column') AS t ( c )
              FOR
                XML PATH('')
              ), 1, 1, '') AS inequality_columns ,
        STUFF(( SELECT  ',' + c.value('(@Name)[1]', 'VARCHAR(128)')
                FROM    MissingIndexNode.nodes('MissingIndexGroup/MissingIndex/
ColumnGroup[@Usage="INCLUDE"]/Column') AS t ( c )
              FOR
                XML PATH('')
              ), 1, 1, '') AS include_columns ,
        sub.usecounts AS qp_usecounts ,
        sub.refcounts AS qp_refcounts ,
        qs.execution_count AS qs_execution_count ,
        qs.last_execution_time AS qs_last_exec_time ,
        qs.total_logical_reads AS qs_total_logical_reads ,
        qs.total_elapsed_time AS qs_total_elapsed_time ,
        qs.total_physical_reads AS qs_total_physical_reads ,
        qs.total_worker_time AS qs_total_worker_time ,
        StmtPlanStub.value('(StmtSimple/@StatementText)[1]', 'varchar(8000)') AS statement_text
FROM    ( SELECT    ROW_NUMBER() OVER ( PARTITION BY qs.plan_handle ORDER BY qs.statement_start_offset ) AS StatementID ,
                    qs.*
          FROM      sys.dm_exec_query_stats qs
        ) AS qs
        JOIN ( SELECT   x.query('../../..') AS StmtPlanStub ,
                        x.query('.') AS MissingIndexNode ,
                        x.value('(../../../@StatementId)[1]', 'int') AS StatementID ,
                        cp.* ,
                        qp.*
               FROM     sys.dm_exec_cached_plans AS cp
                        CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
                        CROSS APPLY qp.query_plan.nodes('/ShowPlanXML/BatchSequence/
Batch/Statements/StmtSimple/
QueryPlan/MissingIndexes/
MissingIndexGroup') mi ( x )
             ) AS sub ON qs.plan_handle = sub.plan_handle
                         AND qs.StatementID = sub.StatementID
GO


--Retrieving Index Usage Information 
SELECT 
	O.Name AS ObjectName	 
	,I.Name AS IndexName	
	,IUS.user_seeks
	,IUS.user_scans
	,IUS.last_user_seek
	,IUS.last_user_scan
FROM sys.dm_db_index_usage_stats AS IUS
INNER JOIN sys.indexes AS I
ON IUS.object_id = I.object_id AND IUS.index_id = I.index_id
INNER JOIN sys.objects AS O
ON IUS.object_id = O.object_id
GO


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

