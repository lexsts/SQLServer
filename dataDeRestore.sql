SELECT MAX(restore_date) AS LastRestore
      ,COUNT(1)  AS CountRestores
      ,destination_database_name
FROM msdb.dbo.restorehistory
GROUP BY destination_database_name