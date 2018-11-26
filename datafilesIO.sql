--Monitor the database files lor all databases.
SELECT
	DB_NAME(vfs.database_id) AS database_name,
	CASE mf.type
		WHEN 0 THEN 'Data File'
		WHEN 1 THEN 'Log File'
	END AS fileType,
	io_stall_read_ms / NULLIF(num_of_reads, 0) AS avg_read_ltency,
	io_stall_write_ms / NULLIF(num_of_writes, 0) AS avg_write_latency,
	io_stall / NULLIF(num_of_reads + num_of_writes, 0) AS avg_total_latency,
	num_of_bytes_read / NULLIF(num_of_reads, 0) AS avg_bytes_per_read,
	num_of_bytes_written / NULLIF(num_of_writes, 0) AS avg_bytes_per_write,
	vfs.io_stall,
	vfs.num_of_reads,
	vfs.num_of_bytes_read,
	vfs.io_stall_read_ms,
	vfs.num_of_writes,
	vfs.num_of_bytes_written,
	vfs.io_stall_write_ms,
	size_on_disk_bytes / 1024 / 1024 AS size_on_disk_mb,
	physical_name	
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
JOIN sys.master_files AS mf
ON vfs.database_id = mf.database_id
AND vfs.FILE_ID = mf.FILE_ID
ORDER BY avg_total_latency DESC


SELECT 
	DB_NAME(VFS.database_id) AS DatabaseName
	,MF.name AS LogicalFileName
	,MF.physical_name AS PhysicalFileName
	,CASE MF.type
		WHEN 0 THEN 'Data File'
		WHEN 1 THEN 'Log File'		
	END AS FileType
	,VFS.num_of_reads AS TotalReadOperations
	,VFS.num_of_bytes_read TotalBytesRead
	,VFS.num_of_writes AS TotalWriteOperations
	,VFS.num_of_bytes_written AS TotalBytesWritten
	,VFS.io_stall_read_ms AS TotalWaitTimeForRead
	,VFS.io_stall_write_ms AS TotalWaitTimeForWrite
	,VFS.io_stall AS TotalWaitTimeForIO	
	,VFS.size_on_disk_bytes AS FileSizeInBytes
FROM sys.dm_io_virtual_file_stats(NULL,NULL) AS VFS
INNER JOIN sys.master_files AS MF
	ON VFS.database_id = MF.database_id AND VFS.file_id = MF.file_id
ORDER BY VFS.database_id DESC
GO


--Monitor the actual database files.
--Observe the read operations.
SELECT 
	DB_NAME(VFS.database_id) AS DatabaseName
	,MF.name AS LogicalFileName
	,MF.physical_name AS PhysicalFileName
	,CASE MF.type
		WHEN 0 THEN 'Data File'
		WHEN 1 THEN 'Log File'		
	END AS FileType
	,VFS.num_of_reads AS TotalReadOperations
	,VFS.num_of_bytes_read TotalBytesRead
	,VFS.num_of_writes AS TotalWriteOperations
	,VFS.num_of_bytes_written AS TotalBytesWritten
	,VFS.io_stall_read_ms AS TotalWaitTimeForRead
	,VFS.io_stall_write_ms AS TotalWaitTimeForWrite
	,VFS.io_stall AS TotalWaitTimeForIO	
	,VFS.size_on_disk_bytes AS FileSizeInBytes
FROM sys.dm_io_virtual_file_stats(DB_ID(),NULL) AS VFS
INNER JOIN sys.master_files AS MF
	ON VFS.database_id = MF.database_id AND VFS.file_id = MF.file_id
ORDER BY VFS.database_id DESC
GO



--Monitor database files for any 
--pending I/O requests.
SELECT 
	DB_NAME(VFS.database_id) AS DatabaseName
	,MF.name AS LogicalFileName
	,MF.physical_name AS PhysicalFileName
	,CASE MF.type
		WHEN 0 THEN 'Data File'
		WHEN 1 THEN 'Log File'		
	END AS FileType
	,PIOR.io_type AS InputOutputOperationType
	,PIOR.io_pending AS Is_Request_Pending	
	,PIOR.io_handle
	,PIOR.scheduler_address 
FROM sys.dm_io_pending_io_requests AS PIOR
INNER JOIN sys.dm_io_virtual_file_stats(NULL,NULL) AS VFS
ON PIOR.io_handle = VFS.file_handle 
INNER JOIN sys.master_files AS MF
ON VFS.database_id = MF.database_id AND VFS.file_id = MF.file_id
GO


/*
To investigating disk I/O issues, use Perfmon and spefifically the:
- Physical Disk\Disk Reads/sec
- Physical Disk\Disk Writes/sec

The key for performance is having the lowest latency possible:
- less than 10ms		= good performance
- between 10ms and 20ms		= slow performance
- between 20ms and 50ms		= poor performance
- greather than 50ms		= significant performance problem.

In addition to the performance counters, high wait times for:
- PAGEIOLATCH_*
- ASYNC_IO_COMPLETION,
- IO_COMPLETION
- WRITELOG

can signs of disk I/O bottlenecks on the server.
*/
