--FULL backup
BACKUP DATABASE [AdventureWorks]
TO DISK = N'D:\SQLBackups\AdventureWorks.bak'
WITH NOFORMAT,
INIT,
NAME = N'AdventureWorks-Full Database Backup',
SKIP,
STATS = 10,
CHECKSUM
GO

--INCREMENTAL/DIFFERENTIAL backup
BACKUP DATABASE [AdventureWorks2012] 
TO  DISK = N'E:\sqldata\backup\AdventureWorks2012.trn' 
WITH  DIFFERENTIAL , 
NOFORMAT, 
NOINIT,  
NAME = N'AdventureWorks2012-Differential Database Backup', 
SKIP, 
NOREWIND, 
NOUNLOAD,  
STATS = 10
GO

--LOG backup
BACKUP LOG [AdventureWorks]
TO DISK = N'D:\SQLBackups\AdventureWorks_Log2.bak'
WITH NOFORMAT,
INIT,
NAME = N'AdventureWorks-Transaction Log Backup',
SKIP,
STATS = 10
GO




--Begin Recovery Process based on transaction
RESTORE DATABASE [AdventureWorks_Copy]
FROM DISK = N'D:\SQLBackups\AdventureWorks.bak'
WITH FILE = 1,
MOVE N'AdventureWorks_Data' TO N'D:\SQLDATA\AdventureWorks_Copy.mdf',
MOVE N'AdventureWorks_Log' TO N'D:\SQLDATA\AdventureWorks_Copy_1.ldf',
NORECOVERY,
STATS = 10
GO

--Restoring the first log backup before a transaction marked ocurr
RESTORE LOG [AdventureWorks_Copy]
FROM DISK = N'D:\SQLBackups\AdventureWorks_Log1.bak'
WITH FILE = 1,
NORECOVERY,
STATS = 10,
STOPBEFOREMARK = N'Delete_Bad_SalesOrderDetail'
GO

--Restoring the second log backup, containing the marked transaction.
RESTORE LOG [AdventureWorks_Copy]
FROM DISK = N'D:\SQLBackups\AdventureWorks_Log2bak'
WITH FILE = 1,
NORECOVERY,
STATS = 10,
STOPBEFOREMARK = N'Delete_Bad_SalesOrderDetail'
GO

--Recovering
RESTORE DATABASE [AdventureWorks_Copy]
WITH RECOVERY
GO






--Begin Recovery Process based on hour
RESTORE DATABASE [AdventureWorks_Copy]
FROM DISK = N'D:\SQLBackups\AdventureWorks.bak'
WITH FILE = 1,
MOVE N'AdventureWorks_Data' TO N'D:\SQLDATA\AdventureWorks_Copy.mdf',
MOVE N'AdventureWorks_Log' TO N'D:\SQLDATA\AdventureWorks_Copy_1.ldf',
STANDBY = N'D:\SQLBackups\AdventureWorks_Copy_UNDO.bak',
STATS = 10
GO

--Restoring log backups to the standby database.
RESTORE LOG [AdventureWorks_Copy]
FROM DISK = N'D:\SQLBackups\AdventureWorks_Log2.bak'
WITH FILE = 1,
STANDBY = N'D:\SQLBackups\AdventureWorks_Copy_UNDO.bak',
STATS = 10,
STOPAT = 'Jan 05, 2011 11:00 AM'
GO
