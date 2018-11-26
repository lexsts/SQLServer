--Check last backups performed for one database
USE msdb ;
SELECT  database_name,
		name,
		user_name,
		backup_set_id ,
        backup_start_date ,
        backup_finish_date ,
	CONVERT(VARCHAR(8), DATEADD(SECOND,DATEDIFF(SECOND,backup_start_date,backup_finish_date),0),108) elapsed_time ,
        CAST(ROUND(backup_size/1024/1024,2,0) AS NUMERIC (18,2)) backup_size_mb ,
        recovery_model ,
        [type]
FROM    dbo.backupset
WHERE   database_name = 'AdventureWorks2012'



--Check the last one backup performed for each database
SELECT  TOP 1 database_name,
		name,
		user_name,
		backup_set_id ,
        backup_start_date ,
        backup_finish_date ,
		CONVERT(VARCHAR(8), DATEADD(SECOND,DATEDIFF(SECOND,backup_start_date,backup_finish_date),0),108) elapsed_time ,
        CAST(ROUND(backup_size/1024/1024,2,0) AS NUMERIC (18,2)) backup_size_mb ,
        recovery_model ,
        [type]
FROM    dbo.backupset
WHERE   database_name = ''?''
ORDER BY backup_finish_date DESC'
