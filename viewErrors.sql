--Value of error log file you want to read: 0 = current, 1 = Archive #1, 2 = Archive #2, etc...
--Log file type: 1 or NULL = error log, 2 = SQL Agent log
--Search string 1: String one you want to search for
--Search string 2: String two you want to search for to further refine the results
--Search from start time  
--Search to end time
--Sort order for results: N'asc' = ascending, N'desc' = descending


-- Shows you where the SQL Server error log is located and how it is configured
SELECT is_enabled, [path], max_size, max_files
FROM sys.dm_os_server_diagnostics_log_configurations WITH (NOLOCK)
OPTION (RECOMPILE);


set nocount on;
DECLARE @tmp_errorLog table
(logDate datetime,
processInfo varchar(200),
Text varchar(4000));

insert into @tmp_errorLog
EXEC sp_readerrorlog;
--EXEC sp_readerrorlog 0, 1;
SELECT * FROM @tmp_errorlog 
--WHERE 
ORDER BY logDate DESC




