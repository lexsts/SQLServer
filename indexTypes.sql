--The following are the best practices you should follow:

--The columns that are going to be included in the WHERE , ORDER BY , GROUP BY , and
--ON clauses of JOIN , should be a part of index key columns and hence, it is supposed
--to be covered by a covering index.

--The columns that are going to be included in the SELECT or HAVING clauses, should
--be covered in the INCLUDE section of the include index. By doing this, we can reduce
--the size of the key columns and B-Tree (Index Tree) of an index, which gives you a
--faster search

--CLUSTERED IN 1 COLUMN
CREATE CLUSTERED INDEX idx_refno ON ordDemo(refno) ON [INDEX]
GO
DROP INDEX [idx_refno_ordDemo] ON [dbo].[ordDemo] WITH ( ONLINE = OFF )
GO

ALTER TABLE REGISTROS ADD CONSTRAINT PK_REGISTROS PRIMARY KEY CLUSTERED 
(
ORDEM ASC
) 
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  ON [INDEX]
GO

--CLUSTERED IN 1 PARTITIONED COLUMN
CREATE UNIQUE CLUSTERED INDEX [PK_REGISTROS] ON registros(ordem) WITH(DROP_EXISTING = ON)ON partsch_registros_ordem(ordem)


--NONCLUSTERED IN 1 COLUMN
CREATE NONCLUSTERED INDEX idx_orderDate_ordDemo
on ordDemo (orderDate)
ON [INDEX]
go
DROP INDEX [idx_orderDate_ordDemo] ON [dbo].[ordDemo]
GO

--NONCLUSTERED IN 2 COLUMNS
CREATE NONCLUSTERED INDEX idx_orderdate_orderId
on ordDemo(orderdate DESC,OrderId ASC)
ON [INDEX]
GO
DROP INDEX [idx_orderdate_orderId] ON [dbo].[ordDemo]
GO


--NONCLUSTERED IN 1 COLUMN INCLUDING ANOTHER
CREATE NONCLUSTERED INDEX idx_orderdate_Included
on ordDemo(orderdate DESC)
INCLUDE(OrderID)
ON [INDEX]
GO
DROP INDEX [idx_orderdate_Included] ON [dbo].[ordDemo]
GO



--NONCLUSTERED IN 1 COLUMN INCLUDING ANOTHER AND A FILTER
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET NUMERIC_ROUNDABORT OFF
GO

CREATE NONCLUSTERED INDEX idx_orderdate_Filtered on ordDemo(orderdate DESC) 
INCLUDE(OrderId)
WHERE OrderDate = '2011-11-28 20:29:00.000'
ON [INDEX]
GO


