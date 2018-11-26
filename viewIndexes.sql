--creating view
CREATE VIEW POView 
WITH SCHEMABINDING 
AS
SELECT
	POH.PurchaseOrderID
	,POH.OrderDate
	,EMP.LoginID
	,V.Name AS VendorName
	,SUM(POD.OrderQty) AS OrderQty
	,SUM(POD.OrderQty*POD.UnitPrice) AS Amount
	,COUNT_BIG(*) AS Count
FROM 
	[Purchasing].[PurchaseOrderHeader] AS POH 
JOIN 
	[Purchasing].[PurchaseOrderDetail] AS POD
ON
	POH.PurchaseOrderID = POD.PurchaseOrderID
JOIN 
	[HumanResources].[Employee] AS EMP
ON
	POH.EmployeeID=EMP.BusinessEntityID
JOIN 
	[Purchasing].[Vendor] AS V
ON
	POH.VendorID=V.BusinessEntityID
GROUP BY
	POH.PurchaseOrderID
	,POH.OrderDate
	,EMP.LoginID
	,V.Name 
GO

--creating clustered Index on View to make POView a materialized view
CREATE UNIQUE CLUSTERED INDEX IndexPOView ON POView (PurchaseOrderID)
GO


--The query is using the index from table (wrong)
SELECT POH.PurchaseOrderID
	,POH.OrderDate
	,EMP.LoginID
	,V.Name AS VendorName
	,SUM(POD.OrderQty) AS OrderQty
	,SUM(POD.OrderQty*POD.UnitPrice) AS Amount
FROM 
	[Purchasing].[PurchaseOrderHeader] AS POH 
JOIN 
	[Purchasing].[PurchaseOrderDetail] AS POD
ON
	POH.PurchaseOrderID = POD.PurchaseOrderID
JOIN 
	[HumanResources].[Employee] AS EMP
ON
	POH.EmployeeID=EMP.BusinessEntityID
JOIN 
	[Purchasing].[Vendor] AS V
ON
	POH.VendorID=V.BusinessEntityID
GROUP BY
	POH.PurchaseOrderID
	,POH.OrderDate
	,EMP.LoginID
	,V.Name 
GO



--Forcing to use index from view (NOEXPAND)
SELECT * FROM POView WITH (NOEXPAND)
GO





--1 ANOTHER EXAMPLE
/****** Script for SelectTopNRows command from SSMS  ******/

SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNING ON
SET NUMERIC_ROUNDABORT OFF
CREATE VIEW V_APONTAMENTOS 
WITH SCHEMABINDING 
AS
SELECT [data]
      ,[ordem]
      ,[nome]
      ,[endereco]
      ,[bairro]
      ,[cidade]
      ,[empresa]
      ,[funcao]
      ,[nacionalidade]
      ,[sexo]
      ,[naturalidade]
  FROM [dbo].[APONTAMENTOS]
  
 CREATE UNIQUE CLUSTERED INDEX PK_V_APONTAMENTOS ON V_APONTAMENTOS (ordem ASC) ON [INDEX]
 GO

--2 ANOTHER EXAMPLE
CREATE VIEW IVAPONTREGIST 
WITH SCHEMABINDING 
AS
SELECT A.data,R.ordem,A.nome,R.endereco,A.bairro,R.cidade,A.empresa,R.funcao,A.nacionalidade,R.sexo,A.naturalidade,A.NUMERO 
FROM DBO.APONTAMENTOS A JOIN DBO.REGISTROS R
ON A.ORDEM=R.ORDEM
WHERE A.ORDEM BETWEEN 1 AND 50000

CREATE UNIQUE CLUSTERED INDEX IX1_IVAPONTREGIST ON IVAPONTREGIST(ORDEM)
CREATE NONCLUSTERED INDEX IX2_IVAPONTREGIST ON IVAPONTREGIST(ORDEM,NUMERO)
CREATE NONCLUSTERED INDEX IX3_IVAPONTREGIST ON IVAPONTREGIST(ORDEM,NUMERO,DATA,ENDERECO,BAIRRO,CIDADE)
CREATE NONCLUSTERED INDEX IX4_IVAPONTREGIST ON IVAPONTREGIST(NUMERO)
--DROP INDEX IX3_IVAPONTREGIST ON IVAPONTREGIST

sp_helpstats 'IVAPONTREGIST', 'ALL'
DBCC SHOW_STATISTICS('IVAPONTREGIST',ST_NUMERO)
GO
--CREATE STATISTICS ST_ORDEM ON IVAPONTREGIST(ORDEM)
--CREATE STATISTICS ST_ORDEM_NUMERO ON IVAPONTREGIST(ORDEM,NUMERO)
--DROP STATISTICS dbo.IVAPONTREGIST.ST_ORDEM
--DROP STATISTICS dbo.IVAPONTREGIST.ST_ORDEM_NUMERO
--UPDATE STATISTICS [dbo].[IVAPONTREGIST]  IX1_IVAPONTREGIST
--UPDATE STATISTICS [dbo].[IVAPONTREGIST]  IX2_IVAPONTREGIST
--UPDATE STATISTICS [dbo].[IVAPONTREGIST]  IX3_IVAPONTREGIST
--UPDATE STATISTICS [dbo].[IVAPONTREGIST]  IX4_IVAPONTREGIST

--Warning! The maximum key length is 900 bytes. The index 'IX3_IVAPONTREGIST' has maximum length of 1036 bytes. For some combination of large values, the insert/update operation will fail.
SELECT SUM(max_length)AS TotalIndexKeySize
FROM sys.columns
WHERE name IN ('ORDEM','NUMERO','DATA','ENDERECO','BAIRRO','CIDADE')
AND object_id = OBJECT_ID(N'IVAPONTREGIST')
SELECT NAME,SUM(max_length)AS TotalIndexKeySize
FROM sys.columns
WHERE name IN ('ORDEM','NUMERO','DATA','ENDERECO','BAIRRO','CIDADE')
AND object_id = OBJECT_ID(N'IVAPONTREGIST')
GROUP BY NAME;

SELECT DISTINCT
	OBJECT_NAME(SI.object_id) as Table_Name
	,SI.[name] AS Statistics_Name
	,STATS_DATE(SI.object_id, SI.index_id) AS Last_Stat_Update_Date
	,SSI.rowmodctr AS RowModCTR
	,SP.rows AS Total_Rows_In_Table
	,'UPDATE STATISTICS ['+SCHEMA_NAME(SO.schema_id)+'].[' 
		+ object_name(SI.object_id) + ']' 
			+ SPACE(2) + SI.[name] AS Update_Stats_Script
FROM sys.indexes AS SI (nolock) JOIN sys.objects AS SO (nolock) 
ON SI.object_id=SO.object_id
JOIN sys.sysindexes SSI (nolock)
ON SI.object_id=SSI.id
AND SI.index_id=SSI.indid 
JOIN sys.partitions AS SP
ON SI.object_id=SP.object_id	
WHERE STATS_DATE(SI.object_id, SI.index_id) IS NOT NULL
--AND SSI.rowmodctr>0
--AND SO.type='U' --Tabela de usuario
AND SO.NAME='IVAPONTREGIST'
ORDER BY SSI.rowmodctr  DESC


SELECT * FROM IVAPONTREGIST WITH (NOEXPAND) --Force to use index view
WHERE ORDEM=10000
GO 

SELECT ORDEM,NUMERO FROM IVAPONTREGIST
WHERE ORDEM=10000
OR NUMERO=20000




--Check indexed view SIZE
SELECT 
	s.Name AS SchemaName,
    v.NAME AS ViewName,
    i.name AS IndexName,
	i.type_desc AS IndexType,
    SUM(p.rows) AS RowCounts,
    SUM(a.total_pages)*8/1024 AS TotalSpaceMB, 
    SUM(a.used_pages)*8/1024 AS UsedSpaceMB, 
    SUM(a.data_pages)*8/1024 AS DataSpaceMB
FROM sys.views v INNER JOIN sys.indexes i ON v.OBJECT_ID = i.object_id
INNER JOIN  sys.schemas s ON s.schema_id = v.schema_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE i.index_id = 1   -- clustered index, remove this to see all indexes
--AND v.Name = 'POView' --View name only, not 'schema.viewname'
GROUP BY s.Name,v.NAME,i.name,i.type_desc
ORDER BY s.Name, v.Name, i.name

