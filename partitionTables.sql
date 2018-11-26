--Amount records: 2169188
SELECT COUNT(*) FROM REGISTROS
--First one: 1
SELECT top 1 * FROM REGISTROS order by ordem asc
--Last one: 2169188
SELECT top 1 * FROM REGISTROS order by ordem desc

--Range Check: 723062
SELECT count(1) FROM REGISTROS where ordem between 1 and 723062
SELECT count(1) FROM REGISTROS where ordem between 723062 and 1446124
SELECT count(1) FROM REGISTROS where ordem between 1446124 and 2169186

--Partition on field int
CREATE PARTITION FUNCTION part_registros_ordem (INT) AS
RANGE LEFT FOR VALUES (723062, 1446124, 2169186)
--drop partition function particao_registros_ordem
--Partition schema
CREATE PARTITION SCHEME part_sch_registros_ordem AS
 PARTITION part_registros_ordem
TO ([FG1], [FG2],[FG4], [FG5])
--drop partition scheme part_sch_registros_ordem

--Alter table to use a partition
CREATE UNIQUE CLUSTERED INDEX [PK_REGISTROS] ON registros(ordem) WITH(DROP_EXISTING = ON)ON part_sch_registros_ordem(ordem)

--Query partition information
--Partitions
SELECT * FROM sys.partition_schemes
SELECT * FROM sys.partition_range_values
WHERE FUNCTION_ID=65536

SELECT t.name,p.partition_number,p.rows,*
FROM sys.partitions AS p
INNER JOIN sys.tables AS t
    ON  p.object_id = t.object_id
WHERE p.partition_id IS NOT NULL
    AND t.name = 'registros';	

--Summary of table partitioned
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object]
     , p.partition_number AS [p#]
     , fg.name AS [filegroup]
     , p.rows
     , au.total_pages AS pages
     , CASE boundary_value_on_right
       WHEN 1 THEN 'less than'
       ELSE 'less than or equal to' END as comparison
     , rv.value
     , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) +
       SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20),
       CONVERT (INT, SUBSTRING (au.first_page, 4, 1) +
       SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) +
       SUBSTRING (au.first_page, 1, 1))) AS first_page
FROM sys.partitions p
INNER JOIN sys.indexes i
     ON p.object_id = i.object_id
AND p.index_id = i.index_id
INNER JOIN sys.objects o
     ON p.object_id = o.object_id
INNER JOIN sys.system_internals_allocation_units au
     ON p.partition_id = au.container_id
INNER JOIN sys.partition_schemes ps
     ON ps.data_space_id = i.data_space_id
INNER JOIN sys.partition_functions f
     ON f.function_id = ps.function_id
INNER JOIN sys.destination_data_spaces dds
     ON dds.partition_scheme_id = ps.data_space_id
     AND dds.destination_id = p.partition_number
INNER JOIN sys.filegroups fg
     ON dds.data_space_id = fg.data_space_id
LEFT OUTER JOIN sys.partition_range_values rv
     ON f.function_id = rv.function_id
     AND p.partition_number = rv.boundary_id
WHERE i.index_id < 2
     AND o.object_id = OBJECT_ID('registros');

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
       ,SCH.name;

SELECT 
	f.[name] AS [FileGroup]
	,d.[physical_name] AS [DatabaseFileName]
	,d.[size]*8/1024 AS [FileSizeMB]
	,d.[max_size]*8/1024 AS [FileMaxSizeMB]	
FROM [sys].[filegroups] f	
INNER JOIN [sys].[database_files] d
	ON f.[data_space_id] = d.[data_space_id]
GROUP BY f.[name],d.[physical_name],d.[size],d.[max_size]
ORDER BY f.[name],d.[physical_name];

Select db_name(),fileid,case when groupid = 0 then 'log file' else 'data file' end,
name,filename, [file_size] = convert(int,round((sysfiles.size*1.000)/128.000,0)),
[space_used] = convert(int,round(fileproperty(sysfiles.name,'SpaceUsed')/128.000,0)),
[space_left] = convert(int,round((sysfiles.size-fileproperty(sysfiles.name,'SpaceUsed'))/128.000,0))
from
dbo.sysfiles;




--Which partition is the data
SELECT $partition.part_registros_ordem(ordem) as nr_particao,* 
FROM dbo.registros
where ordem in (723061,723070,2169186)


--Filegroup VS Partition schema
select sys.partition_schemes.name as name_scheme, sys.data_spaces.name as name_filegroup,*
from sys.partition_schemes
inner join sys.destination_data_spaces on sys.destination_data_spaces.partition_scheme_id = sys.partition_schemes.data_space_id
inner join sys.data_spaces on sys.data_spaces.data_space_id = sys.destination_data_spaces.data_space_id
where sys.partition_schemes.name = 'part_sch_registros_ordem'
--Range in Partition VS Scheme
select sys.partition_functions.name , sys.partition_range_values.* , sys.partition_schemes.name as name_scheme,*
from sys.partition_functions
inner join sys.partition_range_values on sys.partition_range_values.function_id = sys.partition_functions.function_id
inner join sys.partition_schemes      on sys.partition_schemes.function_id      = sys.partition_functions.function_id
where sys.partition_functions.name = 'part_registros_ordem'

--Limit partitions
SELECT t.name AS TableName, i.name AS IndexName, p.partition_number, p.partition_id, i.data_space_id, f.function_id, f.type_desc, r.boundary_id, r.value AS BoundaryValue 
FROM sys.tables AS t
JOIN sys.indexes AS i
    ON t.object_id = i.object_id
JOIN sys.partitions AS p
    ON i.object_id = p.object_id AND i.index_id = p.index_id 
JOIN  sys.partition_schemes AS s 
    ON i.data_space_id = s.data_space_id
JOIN sys.partition_functions AS f 
    ON s.function_id = f.function_id
LEFT JOIN sys.partition_range_values AS r 
    ON f.function_id = r.function_id and r.boundary_id = p.partition_number
WHERE t.name = 'registros' AND i.type <= 1
ORDER BY p.partition_number;

--Column partition
select c.name,*
from  sys.tables          t
join  sys.indexes         i 
      on(i.object_id = t.object_id 
      and i.index_id < 2)
join  sys.index_columns  ic 
      on(ic.partition_ordinal > 0 
      and ic.index_id = i.index_id and ic.object_id = t.object_id)
join  sys.columns         c 
      on(c.object_id = ic.object_id 
      and c.column_id = ic.column_id)
where t.object_id  = object_id('registros')





--Example of drop partition
FG1	0		-	723062
FG2 723062	-	1446124
FG4 1446124	-	2169186 (partition to drop)
FG5	2169186	-	...

--Create a temporary table with the same structure
CREATE TABLE dbo.TEMP_PARTITION (data datetime,ordem int,nome varchar(255),endereco varchar(255),bairro varchar(255),cidade varchar(255),empresa varchar(255),funcao varchar(255),nacionalidade varchar(255),sexo varchar(255),naturalidade varchar(255)) ON FG4

--The properties`s columns and Primary Key must be the same in this temporary table
ALTER TABLE TEMP_PARTITION ALTER COLUMN ORDEM INT NOT NULL;
ALTER TABLE TEMP_PARTITION ALTER COLUMN DATA DATETIME NOT NULL;
CREATE UNIQUE CLUSTERED INDEX PK_TEMP_PARTITION ON TEMP_PARTITION(ordem) WITH(DROP_EXISTING = ON)ON part_sch_registros_ordem(ordem)

--Drop the noclustered indexes on principal table (save the script to recreate it after this process)
DROP INDEX [idx_data_registros] ON [dbo].[REGISTROS]

--Move the partition to the temporary table
ALTER TABLE registros SWITCH PARTITION 3 TO TEMP_PARTITION PARTITION 3

--Remove the temporary table
DROP TABLE dbo.TEMP_PARTITION

--Change the function partition to include these changes
ALTER PARTITION FUNCTION part_registros_ordem()
MERGE RANGE (2169186)
--The scheme is changed automatic (FG4 is not used)
-- Adidionando um Filegroup para a Partition Scheme
-- ALTER PARTITION SCHEME part_sch_registros_ordem
-- NEXT USED FG4;
-- Criando o Intervalo de 2169186
-- ALTER PARTITION FUNCTION part_registros_ordem()
-- SPLIT RANGE (2169186);

--Rebuild the primary key on the principal table
ALTER INDEX [PK_REGISTROS] ON [dbo].[REGISTROS] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

--Recreate the nonclustered indexes on principal table
CREATE NONCLUSTERED INDEX [idx_data_registros] ON [dbo].[REGISTROS]
(
	[data] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [INDEX]
GO







--http://www.devmedia.com.br/particionando-tabelas-e-indices-no-sql-server-2005/5347









