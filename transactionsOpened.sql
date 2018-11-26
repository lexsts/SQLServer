--Detecting Long Running Transaction
SELECT
	ST.session_id
	,ST.transaction_id AS TransactionID
	,DB_NAME(DT.database_id) AS DatabaseName
	,AT.transaction_begin_time AS TransactionStartTime
	,DATEDIFF (SECOND,  AT.transaction_begin_time, GETDATE()) AS TransactionDuration
	,CASE AT.transaction_type
		WHEN 1 THEN 'Read/Write Transaction'
		WHEN 2 THEN 'Read-Only Transaction'
		WHEN 3 THEN 'System Transaction'
		WHEN 4 THEN 'Distributed Transaction'
	END AS TransactionType
	,CASE AT.transaction_state
		WHEN 0 THEN 'Transaction Not Initialized'
		WHEN 1 THEN 'Transaction Initialized & Not Started'
		WHEN 2 THEN 'Active Transaction'
		WHEN 3 THEN 'Transaction Ended'
		WHEN 4 THEN 'Distributed Transaction Initiated Commit Process'
		WHEN 5 THEN 'Transaction in Prepared State & Waiting Resolution'
		WHEN 6 THEN 'Transaction Committed'
		WHEN 7 THEN 'Transaction Rolling Back'
		WHEN 8 THEN 'Transaction Rolled Back'
	END AS TransactionState
FROM sys.dm_tran_session_transactions AS ST
INNER JOIN sys.dm_tran_active_transactions AS AT
ON ST.transaction_id = AT.transaction_id
INNER JOIN sys.dm_tran_database_transactions AS DT
ON ST.transaction_id = DT.transaction_id
ORDER BY TransactionStartTime
GO

--Uncommitted transactions
DBCC OPENTRAN(AdventureWorks2012);

--Visualize o comando executado
--dbcc inputbuffer(56)
--go


