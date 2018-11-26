USE tempdb
GO

--Check if the table exists. If it does,
--drop it first.
IF OBJECT_ID('tempdb.dbo.#tbl_SPWho') IS NOT  NULL
BEGIN
	DROP TABLE tempdb.dbo.#tbl_SPWho
END

--Creating table to store the output 
--sp_who stored procedures.
CREATE TABLE dbo.#tbl_SPWho
(
	spid SMALLINT
	,ecid SMALLINT
	,status NVARCHAR(30)
	,loginame NVARCHAR(128)
	,hostName NVARCHAR(128)
	,blk CHAR(5)
	,dbname NVARCHAR(128)
	,cmd NVARCHAR(16)
	,request_id INT
)

--Insert the result of sp_who stored procedure
--into table.
INSERT INTO dbo.#tbl_SPWho
EXECUTE sp_who
GO

--Check if the table exists. If it does,
--drop it first.
IF OBJECT_ID('tempdb.dbo.#tbl_SPWho2') IS NOT  NULL
BEGIN
	DROP TABLE tempdb.dbo.#tbl_SPWho2
END

CREATE TABLE dbo.#tbl_SPWho2
(
	SPID SMALLINT
	,Status NVARCHAR(30)
	,Login NVARCHAR(128)
	,HostName NVARCHAR(128)
	,BlkBy CHAR(5)
	,DBName NVARCHAR(128)
	,Command NVARCHAR(16)
	,CPUTime INT
	,DiskIO INT
	,LastBatch NVARCHAR(50)
	,ProgramName NVARCHAR(100)
	,SPID2 SMALLINT
	,REQUESTID INT
)
INSERT INTO dbo.#tbl_SPWho2
EXECUTE sp_who2

--Looking at only processes for 
--a particular database.
SELECT 
	 spid AS SessionID
	 ,ecid AS ExecutionContextID
	 ,status AS ProcessStatus
	 ,loginame AS LoginName
	 ,hostName AS HostName
	 ,blk AS BlockedBy
	 ,dbname AS DatabaseName
	 ,cmd AS CommandType
	 ,request_id AS RequestID
FROM dbo.#tbl_SPWho
WHERE dbname = 'AdventureWorks2012'
GO

--Looking at only blocked requests.
SELECT 
	 spid AS SessionID
	 ,ecid AS ExecutionContextID
	 ,status AS ProcessStatus
	 ,loginame AS LoginName
	 ,hostName AS HostName
	 ,blk AS BlockedBy
	 ,dbname AS DatabaseName
	 ,cmd AS CommandType
	 ,request_id AS RequestID
FROM dbo.#tbl_SPWho
WHERE blk > 0

--Looking at only suspended processes.
SELECT 
	 SPID AS SessionID
	 ,Status AS ProcessStatus
	 ,CPUTime
	 ,DiskIO
	 ,ProgramName
	 ,Login AS LoginName
	 ,HostName AS HostName
	 ,BlkBy AS BlockedBy
	 ,DBName AS DatabaseName
	 ,Command AS CommandType
	 ,REQUESTID AS RequestID
FROM dbo.#tbl_SPWho2
WHERE status = 'suspended'




--Visualize o comando executado
--dbcc inputbuffer(76)
--go

--Encerre a sessão
--kill 76;



--SP_WHO and SP_WHO2 are views that have information from sysprocesses
--select * from master.dbo.sysprocesses
