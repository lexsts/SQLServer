--rebulding index idx_refno with ONLINE=ON (online mode)
ALTER INDEX [idx_refno] ON [ordDemo]
REBUILD WITH (FILLFACTOR=80, ONLINE=ON)
GO

--rebuilding index idx_refno with ONLINE=OFF (offline mode)
ALTER INDEX [idx_refno] ON [ordDemo]
REBUILD WITH (FILLFACTOR=80, ONLINE=OFF)
GO

--rebuilding all index on table ordDemo
ALTER INDEX ALL ON [ordDemo]
REBUILD WITH (FILLFACTOR=80, ONLINE=OFF)
GO

--rebuilding idx_reno index with DROP_EXISTING=ON
CREATE CLUSTERED INDEX [idx_refno] ON [ordDemo](refno)
WITH
(
	DROP_EXISTING = ON,
	FILLFACTOR = 70,
	ONLINE = ON
)
GO

--rebuilding all index of ordDemo table
DBCC DBREINDEX ('ordDemo')
GO

--rebuilding idx_refno index of ordDemo table
--with Fill Factor 90
DBCC DBREINDEX ('ordDemo','idx_refno',90)
GO







--reorganizing an index "idx_refno" on "ordDemo" table
--you can't specify, ONLINE & FILLFACTOR option
ALTER INDEX [idx_refno] ON [ordDemo]
REORGANIZE
GO

--reorganizing all index on table ordDemo
ALTER INDEX ALL ON [ordDemo]
REORGANIZE
GO

--reorganizing all index of ordDemo table
--in AdventureWorks2012 database
--give your database and table name in INDEXDEFRAG function
DBCC INDEXDEFRAG ('AdventureWorks2012','ordDemo')
GO

--reorganizing idx_refno index of ordDemo table
--in AdventureWorks2012 database
DBCC INDEXDEFRAG ('AdventureWorks2012','ordDemo','idx_refno')
GO

