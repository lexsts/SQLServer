--Check if the three options below are activate on databases:
--IsAutoCreateStatisticsOn (default is ON/1): Enabling Auto_Create_Statistics creates single column statistics synchronously, as and when needed by the predicate given in the SELECT query.
--IsAutoUpdateStatistics (default is ON/1): The Auto_Update_Statistics option will update statistics that are created by an index, auto-created by Auto_Create_Statistics , or manually created by a user, with the CREATE STATISTICS command.
--is_auto_update_stats_async_on (default is NO/0): if the compiler finds any out-of-date statistics, it doesn't hold your query, instead it compiles the query with old statistics, executes the query, and then updates the statistics, so that the next query will benefit from newly updated statistics.
SELECT 
	CASE 
		WHEN 
			DATABASEPROPERTYEX('AdventureWorks2012','IsAutoCreateStatistics')=1
		THEN
			'Yes'
		ELSE
			'No'
	END as 'IsAutoCreateStatisticsOn?',
	CASE 
		WHEN 
			DATABASEPROPERTYEX('AdventureWorks2012','IsAutoUpdateStatistics')=1
		THEN
			'Yes'
		ELSE
			'No'
	END as 'IsAutoUpdateStatisticsOn?',
	CASE 
		WHEN 
			DATABASEPROPERTYEX('AdventureWorks2012','is_auto_update_stats_async_on')=1
		THEN
			'Yes'
		ELSE
			'No'
	END as 'isAutoUpdateStatsAsyncOn?'
GO 


--ALTER DATABASE AdventureWorks2012 SET AUTO_CREATE_STATISTICS ON --OFF
--ALTER DATABASE AdventureWorks2012 SET AUTO_UPDATE_STATISTICS_ASYNC ON --OFF
--ALTER DATABASE AdventureWorks2012 SET AUTO_UPDATE_STATISTICS_ASYNC ON --OFF


--Query statistics created by SQLServer
SELECT
st.name AS StatName
,COL_NAME(stc.object_id, stc.column_id) AS ColumnName
,OBJECT_NAME(st.object_id) AS TableName
FROM
sys.stats AS st Join sys.stats_columns AS stc
ON
st.stats_id = stc.stats_id AND st.object_id = stc.object_id
WHERE
st.name like '_WA%'
