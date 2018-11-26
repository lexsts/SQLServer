/****************************************************/
/* Created by: Alex Sts. - SQL Server 2012  Profiler*/
/* Date: 12/28/2014  05:02:08 AM         */
/****************************************************/


-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
declare @Options int = 2
declare @Filecount int = 3
set @maxfilesize = 128

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec @rc = sp_trace_create @TraceID output, @Options, N'C:\temp\TPCC_141228_Analise', @maxfilesize, NULL, @Filecount
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 10, 1, @on
exec sp_trace_setevent @TraceID, 10, 3, @on
exec sp_trace_setevent @TraceID, 10, 11, @on
exec sp_trace_setevent @TraceID, 10, 12, @on
exec sp_trace_setevent @TraceID, 10, 13, @on
exec sp_trace_setevent @TraceID, 10, 35, @on
exec sp_trace_setevent @TraceID, 45, 1, @on
exec sp_trace_setevent @TraceID, 45, 3, @on
exec sp_trace_setevent @TraceID, 45, 11, @on
exec sp_trace_setevent @TraceID, 45, 12, @on
exec sp_trace_setevent @TraceID, 45, 13, @on
exec sp_trace_setevent @TraceID, 45, 28, @on
exec sp_trace_setevent @TraceID, 45, 35, @on
exec sp_trace_setevent @TraceID, 12, 1, @on
exec sp_trace_setevent @TraceID, 12, 3, @on
exec sp_trace_setevent @TraceID, 12, 11, @on
exec sp_trace_setevent @TraceID, 12, 12, @on
exec sp_trace_setevent @TraceID, 12, 13, @on
exec sp_trace_setevent @TraceID, 12, 35, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

exec sp_trace_setfilter @TraceID, 35, 0, 6, N'tpcc'
-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go




/*
--Get id from the trace
SELECT id from sys.traces WHERE path like 'C:\temp\TPCC_141228_Analise%'

--Stop the trace
EXECUTE sp_trace_setstatus @traceid=2,@status=0

--Closes the trace
EXECUTE sp_trace_setstatus @traceid=2,@status=2


--Retrieve the collected trace data.
SELECT
TE.name AS TraceEvent
,TD.DatabaseName
,TD.FileName
,TD.StartTime
,TD.EndTime
FROM fn_trace_gettable('C:\temp\TPCC_141228_Analise_1.trc',default) AS
TD
LEFT JOIN sys.trace_events AS TE
ON TD.EventClass = TE.trace_event_id
/*
