--manually create stats
--CREATE STATISTICS <<Statastics name>> ON
--<<SCHEMA NAME>>.<<TABLE NAME>>(<<COLUMN NAME>>)
CREATE STATISTICS st_DueDate_SalesOrderHeader ON Sales.SalesOrderHeader(DueDate)




--update statistics for Sales.SalesOrderHeader Table
UPDATE STATISTICS Sales.SalesOrderHeader;




--update statistics for st_DueDate_SalesOrderHeader stats
--of Sales.SalesOrderHeader Table
UPDATE STATISTICS Sales.SalesOrderHeader st_DueDate_
SalesOrderHeader




--update all statistics available in database
EXEC sp_updatestats




--manually deleting stats
--DROP STATISTICS
--<<SCHEMA NAME>>.<<TABLE NAME>>.<<Statastics name>>
DROP STATISTICS Sales.SalesOrderHeader.st_DueDate_SalesOrderHeader





--Check columns and keys values
sp_helpstats 'IVAPONTREGIST', 'ALL'
DBCC SHOW_STATISTICS('IVAPONTREGIST',ST_NUMERO)
--CREATE STATISTICS st_DueDate_SalesOrderHeader ON Sales.SalesOrderHeader(DueDate)
--UPDATE STATISTICS Sales.SalesOrderHeader;
--DROP STATISTICS Sales.SalesOrderHeader.st_DueDate_SalesOrderHeader
GO
