--On the select above we have a index scan because a lack of index on column duedate
SELECT
s.SalesOrderID,
so.SalesOrderDetailID
FROM
SalesOrdDemo AS s join Sales.SalesOrderDetail AS so
ON
s.SalesOrderID = so.SalesOrderID
WHERE
s.DueDate='2005-09-19 00:00:00.000'


--Create a statistics in this column allow that a index seek to be executed
CREATE STATISTICS st_SaledOrdDemo_DueDate ON SalesOrdDemo(DueDate)


--Quering statistics for a specific object
SELECT
object_id
,OBJECT_NAME(object_id) AS TableName
,name AS StatisticsName
,auto_created
FROM
sys.stats
where object_id=OBJECT_ID('SalesOrdDemo')
Order by object_id desc
GO
