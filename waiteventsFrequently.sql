select * from sys.dm_os_wait_stats 
where waiting_tasks_count <> 0
and wait_type not like 'FT_%'
order by 3 desc


--http://msdn.microsoft.com/pt-br/library/ms179984.aspx

--System session waits
SELECT DISTINCT
        wt.wait_type
FROM    sys.dm_os_waiting_tasks AS wt
        JOIN sys.dm_exec_sessions AS s ON wt.session_id = s.session_id
WHERE   s.is_user_process = 0 

--Verifying CPU pressure via signal wait time.
SELECT  SUM(signal_wait_time_ms) AS TotalSignalWaitTime ,
        ( SUM(CAST(signal_wait_time_ms AS NUMERIC(20, 2)))
          / SUM(CAST(wait_time_ms AS NUMERIC(20, 2))) * 100 ) AS PercentageSignalWaitsOfTotalTime
FROM    sys.dm_os_wait_stats


--Top 10 Cumulative wait events
--DBCC SQLPERF('sys.dm_os_wait_stats',CLEAR);
--CPU: cxpacket, cmemthread, sos_scheduler_yield
SELECT TOP 10
        wait_type ,
        max_wait_time_ms wait_time_ms ,
        signal_wait_time_ms ,
        wait_time_ms - signal_wait_time_ms AS resource_wait_time_ms ,
        100.0 * wait_time_ms / SUM(wait_time_ms) OVER ( )
                                    AS percent_total_waits ,
        100.0 * signal_wait_time_ms / SUM(signal_wait_time_ms) OVER ( )
                                    AS percent_total_signal_waits ,
        100.0 * ( wait_time_ms - signal_wait_time_ms )
        / SUM(wait_time_ms) OVER ( ) AS percent_total_resource_waits
FROM    sys.dm_os_wait_stats
WHERE   wait_time_ms > 0 -- remove zero wait_time
        AND wait_type NOT IN -- filter out additional irrelevant waits
( 'SLEEP_TASK', 'BROKER_TASK_STOP', 'BROKER_TO_FLUSH',
  'SQLTRACE_BUFFER_FLUSH','CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT',
  'LAZYWRITER_SLEEP', 'SLEEP_SYSTEMTASK', 'SLEEP_BPOOL_FLUSH',
  'BROKER_EVENTHANDLER', 'XE_DISPATCHER_WAIT', 'FT_IFTSHC_MUTEX',
  'CHECKPOINT_QUEUE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
  'BROKER_TRANSMITTER', 'FT_IFTSHC_MUTEX', 'KSOURCE_WAKEUP',
  'LAZYWRITER_SLEEP', 'LOGMGR_QUEUE', 'ONDEMAND_TASK_QUEUE',
  'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BAD_PAGE_PROCESS',
  'DBMIRROR_EVENTS_QUEUE', 'BROKER_RECEIVE_WAITFOR',
  'PREEMPTIVE_OS_GETPROCADDRESS', 'PREEMPTIVE_OS_AUTHENTICATIONOPS',
  'WAITFOR', 'DISPATCHER_QUEUE_SEMAPHORE', 'XE_DISPATCHER_JOIN',
  'RESOURCE_QUEUE' )
        AND wait_type NOT IN -- remove system waits
( 'KSOURCE_WAKEUP', 'BROKER_TASK_STOP', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
  'SQLTRACE_BUFFER_FLUSH', 'CLR_AUTO_EVENT', 'BROKER_EVENTHANDLER',
  'BAD_PAGE_PROCESS', 'BROKER_TRANSMITTER', 'CHECKPOINT_QUEUE',
  'DBMIRROR_EVENTS_QUEUE', 'SQLTRACE_BUFFER_FLUSH', 'CLR_MANUAL_EVENT',
  'ONDEMAND_TASK_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'LOGMGR_QUEUE',
  'BROKER_RECEIVE_WAITFOR', 'PREEMPTIVE_OS_GETPROCADDRESS',
  'PREEMPTIVE_OS_AUTHENTICATIONOPS', 'BROKER_TO_FLUSH' )
ORDER BY wait_time_ms DESC


--Show max memory [(max memory / 4) * 300]
--Index Searches/sec
sp_configure 'show advanced option', '1'
RECONFIGURE;
EXEC sp_configure 'max server memory (MB)';


--Performance Counters
DECLARE @CounterPrefix NVARCHAR(30)
SET @CounterPrefix = CASE
    WHEN @@SERVICENAME = 'MSSQLSERVER'
    THEN 'SQLServer:'
    ELSE 'MSSQL$'+@@SERVICENAME+':'
    END;
-- Capture the first counter set
SELECT CAST(1 AS INT) AS collection_instance ,
      [OBJECT_NAME] ,
      counter_name ,
      instance_name ,
      cntr_value ,
      cntr_type ,
      CURRENT_TIMESTAMP AS collection_time
INTO #perf_counters_init
FROM sys.dm_os_performance_counters
WHERE ( OBJECT_NAME = @CounterPrefix+'Access Methods'
         AND counter_name = 'Full Scans/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Access Methods'
           AND counter_name = 'Index Searches/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Buffer Manager'
           AND counter_name = 'Lazy Writes/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Buffer Manager'
      AND counter_name = 'Page life expectancy'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'General Statistics'
           AND counter_name = 'Processes Blocked'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'General Statistics'
           AND counter_name = 'User Connections'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Locks'
           AND counter_name = 'Lock Waits/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Locks'
           AND counter_name = 'Lock Wait Time (ms)'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'SQL Statistics'
           AND counter_name = 'SQL Re-Compilations/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Memory Manager'
           AND counter_name = 'Memory Grants Pending'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'SQL Statistics'
           AND counter_name = 'Batch Requests/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'SQL Statistics'
           AND counter_name = 'SQL Compilations/sec'
)

-- Wait on Second between data collection
WAITFOR DELAY '00:00:30'

-- Capture the second counter set
SELECT CAST(2 AS INT) AS collection_instance ,
       OBJECT_NAME ,
       counter_name ,
       instance_name ,
       cntr_value ,
       cntr_type ,
       CURRENT_TIMESTAMP AS collection_time
INTO #perf_counters_second
FROM sys.dm_os_performance_counters
WHERE ( OBJECT_NAME = @CounterPrefix+'Access Methods'
      AND counter_name = 'Full Scans/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Access Methods'
           AND counter_name = 'Index Searches/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Buffer Manager'
           AND counter_name = 'Lazy Writes/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Buffer Manager'
           AND counter_name = 'Page life expectancy'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'General Statistics'
           AND counter_name = 'Processes Blocked'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'General Statistics'
           AND counter_name = 'User Connections'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Locks'
           AND counter_name = 'Lock Waits/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Locks'
           AND counter_name = 'Lock Wait Time (ms)'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'SQL Statistics'
           AND counter_name = 'SQL Re-Compilations/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'Memory Manager'
           AND counter_name = 'Memory Grants Pending'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'SQL Statistics'
           AND counter_name = 'Batch Requests/sec'
      )
      OR ( OBJECT_NAME = @CounterPrefix+'SQL Statistics'
           AND counter_name = 'SQL Compilations/sec'
)

-- Calculate the cumulative counter values
SELECT  i.OBJECT_NAME ,
        i.counter_name ,
        i.instance_name ,
        CASE WHEN i.cntr_type = 272696576
          THEN s.cntr_value - i.cntr_value
          WHEN i.cntr_type = 65792 THEN s.cntr_value
        END AS cntr_value
FROM #perf_counters_init AS i
  JOIN  #perf_counters_second AS s
    ON i.collection_instance + 1 = s.collection_instance
      AND i.OBJECT_NAME = s.OBJECT_NAME
      AND i.counter_name = s.counter_name
      AND i.instance_name = s.instance_name
ORDER BY OBJECT_NAME

-- Cleanup tables
DROP TABLE #perf_counters_init
DROP TABLE #perf_counters_second 



