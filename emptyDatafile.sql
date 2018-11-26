--Move data between datafiles from the same filegroup
USE [AdventureWorks2012]
GO
DBCC SHRINKFILE (N'AdventureWorks2012_Index2' , EMPTYFILE)
GO
ALTER DATABASE [AdventureWorks2012]  REMOVE FILE [AdventureWorks2012_Index2]
GO

