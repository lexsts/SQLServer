--DBCC FREEPROCCACHE() --Clear the execution plan on memory
--DBCC DROPCLEANBUFFERS() --Clear the data on memory from queries recently executed

--Verify the trace has been created.
SELECT * FROM sys.traces
SELECT * FROM ::fn_trace_getinfo(default)
SELECT * FROM ::fn_trace_geteventinfo(default)
SELECT * FROM ::fn_trace_getfilterinfo(default)

--Events codes
select * from sys.trace_events

--Column codes
select * from sys.trace_columns

--Event Bindings
select * from sys.trace_event_bindings

--Permission
USE master;
GRANT ALTER TRACE TO LoginID;
REVOKE ALTER TRACE FROM LoginID; 


--Start the trace
/****************************************************/
/* Created by: SQL Server 2012  Profiler          */
/* Date: 02/25/2015  05:55:13 AM         */

/* LONG QUERIES - (Groups: Duration / Columns: EventSequence, SPID, EventClass, ApplicationName, DatabaseName, LoginName, CPU, Reads, Writes, RowCounts)
/* Errors and Warnings: Exception, Execution Warnings, User Error Message, [ErrorLog, EventLog - MASTER], (Attention)	*/
/* Performance: Showplan XML	*/
/* Stored Procedures: RPC:Completed, (RPC:Starting), (SP:StmtStarting), SP:StmtCompleted 	*/
/* TSQL: SQL:BatchStarting, SQL:BatchCompleted, (SQL:StmtStarting), SQL:StmtCompleted	*/

/* DEADLOCK EVENTS
/* Locks: Deadlock graph, Lock: Deadlock, Lock: Deadlock Chain
/* Stored Procedures: RPC:Completed, SP:StmtCompleted	*/
/* TSQL: SQL:BatchStarting, SQL:BatchCompleted	*/

/* BLOCKING ISSUES
/* Errors and Warnings: Blocked process report*/

/* EXCESSIVE AUTOSTATS
/* Performance: Auto Stats*/

/* EXCESSIVE COMPILATIONS
/* Stored Procedures: RPC:Completed, SP:StmtCompleted	*/
/* TSQL: SQL:BatchStarting, SQL:BatchCompleted, SQL:StmtCompleted, SQL:StmtRecompile, SQL:StmtStarting	*/
/* Performance: Auto Stats*/

/* EXCESSIVE DATABASE FILE GROWTH/SHRINKAGE
/* Database: Data File AutoGrow, Data File Auto Shrink, Log File AutoGrow, Log File Auto Shrink	*/

/* EXCESSIVE TABLE/INDEX SCANS
/* Performance: Showplan XML	*/
/* Stored Procedures: RPC:Completed, SP:StmtCompleted	*/
/* TSQL: SQL:BatchStarting, SQL:BatchCompleted	*/

/* MEMORY PROBLEMS
/* Errors and Warnings: Execution Warnings, Sort Warnings	*/
/* Server: Server Memory Change		*/
/* Stored Procedures: RPC:Completed, SP:StmtCompleted	*/
/* TSQL: SQL:BatchStarting, SQL:BatchCompleted	*/
/****************************************************/
-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
declare @DateTime datetime

set @DateTime = '2015-02-25 07:40:10.000' --LIMIT DATE
set @maxfilesize = 512 --LIMIT SIZE FILE

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec @rc = sp_trace_create @TraceID output, 0, N'C:\TEMP\TraceLongQueries', @maxfilesize, @Datetime --PLACE FILE
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 122, 1, @on
exec sp_trace_setevent @TraceID, 122, 9, @on
exec sp_trace_setevent @TraceID, 122, 2, @on
exec sp_trace_setevent @TraceID, 122, 66, @on
exec sp_trace_setevent @TraceID, 122, 10, @on
exec sp_trace_setevent @TraceID, 122, 3, @on
exec sp_trace_setevent @TraceID, 122, 4, @on
exec sp_trace_setevent @TraceID, 122, 5, @on
exec sp_trace_setevent @TraceID, 122, 7, @on
exec sp_trace_setevent @TraceID, 122, 8, @on
exec sp_trace_setevent @TraceID, 122, 11, @on
exec sp_trace_setevent @TraceID, 122, 12, @on
exec sp_trace_setevent @TraceID, 122, 14, @on
exec sp_trace_setevent @TraceID, 122, 22, @on
exec sp_trace_setevent @TraceID, 122, 25, @on
exec sp_trace_setevent @TraceID, 122, 26, @on
exec sp_trace_setevent @TraceID, 122, 28, @on
exec sp_trace_setevent @TraceID, 122, 29, @on
exec sp_trace_setevent @TraceID, 122, 34, @on
exec sp_trace_setevent @TraceID, 122, 35, @on
exec sp_trace_setevent @TraceID, 122, 41, @on
exec sp_trace_setevent @TraceID, 122, 49, @on
exec sp_trace_setevent @TraceID, 122, 50, @on
exec sp_trace_setevent @TraceID, 122, 51, @on
exec sp_trace_setevent @TraceID, 122, 60, @on
exec sp_trace_setevent @TraceID, 122, 64, @on
exec sp_trace_setevent @TraceID, 10, 1, @on
exec sp_trace_setevent @TraceID, 10, 9, @on
exec sp_trace_setevent @TraceID, 10, 2, @on
exec sp_trace_setevent @TraceID, 10, 66, @on
exec sp_trace_setevent @TraceID, 10, 10, @on
exec sp_trace_setevent @TraceID, 10, 3, @on
exec sp_trace_setevent @TraceID, 10, 4, @on
exec sp_trace_setevent @TraceID, 10, 6, @on
exec sp_trace_setevent @TraceID, 10, 7, @on
exec sp_trace_setevent @TraceID, 10, 8, @on
exec sp_trace_setevent @TraceID, 10, 11, @on
exec sp_trace_setevent @TraceID, 10, 12, @on
exec sp_trace_setevent @TraceID, 10, 13, @on
exec sp_trace_setevent @TraceID, 10, 14, @on
exec sp_trace_setevent @TraceID, 10, 15, @on
exec sp_trace_setevent @TraceID, 10, 16, @on
exec sp_trace_setevent @TraceID, 10, 17, @on
exec sp_trace_setevent @TraceID, 10, 18, @on
exec sp_trace_setevent @TraceID, 10, 25, @on
exec sp_trace_setevent @TraceID, 10, 26, @on
exec sp_trace_setevent @TraceID, 10, 31, @on
exec sp_trace_setevent @TraceID, 10, 34, @on
exec sp_trace_setevent @TraceID, 10, 35, @on
exec sp_trace_setevent @TraceID, 10, 41, @on
exec sp_trace_setevent @TraceID, 10, 48, @on
exec sp_trace_setevent @TraceID, 10, 49, @on
exec sp_trace_setevent @TraceID, 10, 50, @on
exec sp_trace_setevent @TraceID, 10, 51, @on
exec sp_trace_setevent @TraceID, 10, 60, @on
exec sp_trace_setevent @TraceID, 10, 64, @on
exec sp_trace_setevent @TraceID, 45, 1, @on
exec sp_trace_setevent @TraceID, 45, 9, @on
exec sp_trace_setevent @TraceID, 45, 3, @on
exec sp_trace_setevent @TraceID, 45, 4, @on
exec sp_trace_setevent @TraceID, 45, 5, @on
exec sp_trace_setevent @TraceID, 45, 6, @on
exec sp_trace_setevent @TraceID, 45, 7, @on
exec sp_trace_setevent @TraceID, 45, 8, @on
exec sp_trace_setevent @TraceID, 45, 10, @on
exec sp_trace_setevent @TraceID, 45, 11, @on
exec sp_trace_setevent @TraceID, 45, 12, @on
exec sp_trace_setevent @TraceID, 45, 13, @on
exec sp_trace_setevent @TraceID, 45, 14, @on
exec sp_trace_setevent @TraceID, 45, 15, @on
exec sp_trace_setevent @TraceID, 45, 16, @on
exec sp_trace_setevent @TraceID, 45, 17, @on
exec sp_trace_setevent @TraceID, 45, 18, @on
exec sp_trace_setevent @TraceID, 45, 22, @on
exec sp_trace_setevent @TraceID, 45, 25, @on
exec sp_trace_setevent @TraceID, 45, 26, @on
exec sp_trace_setevent @TraceID, 45, 28, @on
exec sp_trace_setevent @TraceID, 45, 29, @on
exec sp_trace_setevent @TraceID, 45, 34, @on
exec sp_trace_setevent @TraceID, 45, 35, @on
exec sp_trace_setevent @TraceID, 45, 41, @on
exec sp_trace_setevent @TraceID, 45, 48, @on
exec sp_trace_setevent @TraceID, 45, 49, @on
exec sp_trace_setevent @TraceID, 45, 50, @on
exec sp_trace_setevent @TraceID, 45, 51, @on
exec sp_trace_setevent @TraceID, 45, 55, @on
exec sp_trace_setevent @TraceID, 45, 60, @on
exec sp_trace_setevent @TraceID, 45, 61, @on
exec sp_trace_setevent @TraceID, 45, 62, @on
exec sp_trace_setevent @TraceID, 45, 64, @on
exec sp_trace_setevent @TraceID, 45, 66, @on
exec sp_trace_setevent @TraceID, 12, 1, @on
exec sp_trace_setevent @TraceID, 12, 9, @on
exec sp_trace_setevent @TraceID, 12, 3, @on
exec sp_trace_setevent @TraceID, 12, 11, @on
exec sp_trace_setevent @TraceID, 12, 4, @on
exec sp_trace_setevent @TraceID, 12, 6, @on
exec sp_trace_setevent @TraceID, 12, 7, @on
exec sp_trace_setevent @TraceID, 12, 8, @on
exec sp_trace_setevent @TraceID, 12, 10, @on
exec sp_trace_setevent @TraceID, 12, 12, @on
exec sp_trace_setevent @TraceID, 12, 13, @on
exec sp_trace_setevent @TraceID, 12, 14, @on
exec sp_trace_setevent @TraceID, 12, 15, @on
exec sp_trace_setevent @TraceID, 12, 16, @on
exec sp_trace_setevent @TraceID, 12, 17, @on
exec sp_trace_setevent @TraceID, 12, 18, @on
exec sp_trace_setevent @TraceID, 12, 26, @on
exec sp_trace_setevent @TraceID, 12, 31, @on
exec sp_trace_setevent @TraceID, 12, 35, @on
exec sp_trace_setevent @TraceID, 12, 41, @on
exec sp_trace_setevent @TraceID, 12, 48, @on
exec sp_trace_setevent @TraceID, 12, 49, @on
exec sp_trace_setevent @TraceID, 12, 50, @on
exec sp_trace_setevent @TraceID, 12, 51, @on
exec sp_trace_setevent @TraceID, 12, 60, @on
exec sp_trace_setevent @TraceID, 12, 64, @on
exec sp_trace_setevent @TraceID, 12, 66, @on
exec sp_trace_setevent @TraceID, 13, 1, @on
exec sp_trace_setevent @TraceID, 13, 9, @on
exec sp_trace_setevent @TraceID, 13, 3, @on
exec sp_trace_setevent @TraceID, 13, 11, @on
exec sp_trace_setevent @TraceID, 13, 4, @on
exec sp_trace_setevent @TraceID, 13, 6, @on
exec sp_trace_setevent @TraceID, 13, 7, @on
exec sp_trace_setevent @TraceID, 13, 8, @on
exec sp_trace_setevent @TraceID, 13, 10, @on
exec sp_trace_setevent @TraceID, 13, 12, @on
exec sp_trace_setevent @TraceID, 13, 14, @on
exec sp_trace_setevent @TraceID, 13, 26, @on
exec sp_trace_setevent @TraceID, 13, 35, @on
exec sp_trace_setevent @TraceID, 13, 41, @on
exec sp_trace_setevent @TraceID, 13, 49, @on
exec sp_trace_setevent @TraceID, 13, 50, @on
exec sp_trace_setevent @TraceID, 13, 51, @on
exec sp_trace_setevent @TraceID, 13, 60, @on
exec sp_trace_setevent @TraceID, 13, 64, @on
exec sp_trace_setevent @TraceID, 13, 66, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

exec sp_trace_setfilter @TraceID, 8, 0, 6, N'SRVWIN04' --HOSTNAME
exec sp_trace_setfilter @TraceID, 10, 0, 6, N'Microsoft SQL Server Management Studio - Query' --APPLICATION
exec sp_trace_setfilter @TraceID, 11, 0, 6, N'alexsantos' --LOGIN NAME
set @bigintfilter = 10000 --DURATION MICROSECONDS
exec sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter --DURATION MICROSECONDS
exec sp_trace_setfilter @TraceID, 35, 0, 6, N'AdventureWorks2012' --DATABASE NAME
-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go
/****************************************************/
/* END						    */
/****************************************************/


--Stop the trace
DECLARE @TraceID INT
DECLARE @TraceFile NVARCHAR(245) = 'C:\temp\SQL2012_Performance\Trace\FileAutoGrow.trc'

--Get the TraceID for our trace.
SELECT @TraceID = id FROM sys.traces 
WHERE path = @TraceFile

IF @TraceID IS NOT NULL
BEGIN
	--Stop the trace. Status 0 corroponds to STOP.
	EXECUTE sp_trace_setstatus 
		@traceid = @TraceID
		,@status = 0
		
	--Closes the trace. Status 2 corroponds to CLOSE.
	EXECUTE sp_trace_setstatus 
		@traceid = @TraceID
		,@status = 2	
END
GO



--Retrieve the collected trace data.
SELECT SPID,TD.EventSequence,TE.NAME AS "EventName",DATABASENAME,LOGINNAME,APPLICATIONNAME,STARTTIME,ENDTIME
,DURATION/1000 AS "DURATION(ms)",OBJECTNAME,TEXTDATA,CPU,READS,WRITES,INTEGERDATA AS NUMROWS,BINARYDATA
FROM ::fn_trace_gettable('U:\sqldata\trace\ErrorFind.trc', default) AS TD
INNER JOIN sys.trace_events AS TE --IGNORE LINES START/STOP
ON TD.EventClass = TE.trace_event_id

SELECT TE.NAME,*
FROM fn_trace_gettable('U:\sqldata\trace\ErrorFind.trc',default) AS TD
INNER JOIN sys.trace_events AS TE --IGNORE LINES START/STOP TRACE
ON TD.EventClass = TE.trace_event_id
WHERE TD.EventSequence=2734

--Verify the duration of executions
SELECT COUNT(*) AS TotalExecutions
  , SPID
  , TD.EventSequence  
  , TE.NAME AS "EventName"
  , SUM(Duration/1000) AS "Duration_Total (ms)"
  , SUM(CPU) AS CPU_Total
  , SUM(Reads) AS Reads_Total
  , SUM(Writes) AS Writes_Total
  , CAST(TextData AS NVARCHAR(MAX)) TextData
  , DATABASENAME, LOGINNAME, HOSTNAME, APPLICATIONNAME     
FROM ::fn_trace_gettable('C:\TEMP\TRACEWORKLOAD.trc', default) AS TD
INNER JOIN sys.trace_events AS TE --IGNORE LINES START/STOP
ON TD.EventClass = TE.trace_event_id
WHERE TE.NAME <> 'Showplan XML'
AND Duration IS NOT NULL
GROUP BY SPID,DATABASENAME, LOGINNAME, HOSTNAME, APPLICATIONNAME,TD.EventSequence,TE.NAME, CAST(TextData AS NVARCHAR(MAX))
ORDER BY TD.EventSequence ASC

SELECT CAST(TextData AS NVARCHAR(MAX)) TextData
  , SUM(Duration/1000) AS "Duration_Total (ms)"
  , AVG(Duration/1000) AS "Duration_Media (ms)"
  , COUNT(Duration) AS "Duration_Count"  
  , SUM(CPU) AS CPU_Total
  , SUM(Reads) AS Reads_Total
  , SUM(Writes) AS Writes_Total
FROM ::fn_trace_gettable('C:\TEMP\TRACEWORKLOAD.trc', default) AS TD
INNER JOIN sys.trace_events AS TE --IGNORE LINES START/STOP
ON TD.EventClass = TE.trace_event_id
WHERE TE.NAME <> 'Showplan XML'
AND Duration IS NOT NULL
GROUP BY SPID,DATABASENAME, LOGINNAME, HOSTNAME, APPLICATIONNAME,TD.EventSequence,TE.NAME, CAST(TextData AS NVARCHAR(MAX))
ORDER BY TD.EventSequence ASC


--sys.trace_events 
trace_event_id	category_id	name
10	11	RPC:Completed
11	11	RPC:Starting
12	13	SQL:BatchCompleted
13	13	SQL:BatchStarting
14	8	Audit Login
15	8	Audit Logout
16	3	Attention
17	10	ExistingConnection
18	8	Audit Server Starts And Stops
19	12	DTCTransaction
20	8	Audit Login Failed
21	3	EventLog
22	3	ErrorLog
23	4	Lock:Released
24	4	Lock:Acquired
25	4	Lock:Deadlock
26	4	Lock:Cancel
27	4	Lock:Timeout
28	6	Degree of Parallelism
33	3	Exception
34	11	SP:CacheMiss
35	11	SP:CacheInsert
36	11	SP:CacheRemove
37	11	SP:Recompile
38	11	SP:CacheHit
40	13	SQL:StmtStarting
41	13	SQL:StmtCompleted
42	11	SP:Starting
43	11	SP:Completed
44	11	SP:StmtStarting
45	11	SP:StmtCompleted
46	5	Object:Created
47	5	Object:Deleted
50	12	SQLTransaction
51	7	Scan:Started
52	7	Scan:Stopped
53	1	CursorOpen
54	12	TransactionLog
55	3	Hash Warning
58	6	Auto Stats
59	4	Lock:Deadlock Chain
60	4	Lock:Escalation
61	15	OLEDB Errors
67	3	Execution Warnings
68	6	Showplan Text (Unencoded)
69	3	Sort Warnings
70	1	CursorPrepare
71	13	Prepare SQL
72	13	Exec Prepared SQL
73	13	Unprepare SQL
74	1	CursorExecute
75	1	CursorRecompile
76	1	CursorImplicitConversion
77	1	CursorUnprepare
78	1	CursorClose
79	3	Missing Column Statistics
80	3	Missing Join Predicate
81	9	Server Memory Change
82	14	UserConfigurable:0
83	14	UserConfigurable:1
84	14	UserConfigurable:2
85	14	UserConfigurable:3
86	14	UserConfigurable:4
87	14	UserConfigurable:5
88	14	UserConfigurable:6
89	14	UserConfigurable:7
90	14	UserConfigurable:8
91	14	UserConfigurable:9
92	2	Data File Auto Grow
93	2	Log File Auto Grow
94	2	Data File Auto Shrink
95	2	Log File Auto Shrink
96	6	Showplan Text
97	6	Showplan All
98	6	Showplan Statistics Profile
100	11	RPC Output Parameter
102	8	Audit Database Scope GDR Event
103	8	Audit Schema Object GDR Event
104	8	Audit Addlogin Event
105	8	Audit Login GDR Event
106	8	Audit Login Change Property Event
107	8	Audit Login Change Password Event
108	8	Audit Add Login to Server Role Event
109	8	Audit Add DB User Event
110	8	Audit Add Member to DB Role Event
111	8	Audit Add Role Event
112	8	Audit App Role Change Password Event
113	8	Audit Statement Permission Event
114	8	Audit Schema Object Access Event
115	8	Audit Backup/Restore Event
116	8	Audit DBCC Event
117	8	Audit Change Audit Event
118	8	Audit Object Derived Permission Event
119	15	OLEDB Call Event
120	15	OLEDB QueryInterface Event
121	15	OLEDB DataRead Event
122	6	Showplan XML
123	6	SQL:FullTextQuery
124	16	Broker:Conversation
125	18	Deprecation Announcement
126	18	Deprecation Final Support
127	3	Exchange Spill Event
128	8	Audit Database Management Event
129	8	Audit Database Object Management Event
130	8	Audit Database Principal Management Event
131	8	Audit Schema Object Management Event
132	8	Audit Server Principal Impersonation Event
133	8	Audit Database Principal Impersonation Event
134	8	Audit Server Object Take Ownership Event
135	8	Audit Database Object Take Ownership Event
136	16	Broker:Conversation Group
137	3	Blocked process report
138	16	Broker:Connection
139	16	Broker:Forwarded Message Sent
140	16	Broker:Forwarded Message Dropped
141	16	Broker:Message Classify
142	16	Broker:Transmission
143	16	Broker:Queue Disabled
144	16	Broker:Mirrored Route State Changed
146	6	Showplan XML Statistics Profile
148	4	Deadlock graph
149	16	Broker:Remote Message Acknowledgement
150	9	Trace File Close
151	2	Database Mirroring Connection
152	8	Audit Change Database Owner
153	8	Audit Schema Object Take Ownership Event
154	8	Audit Database Mirroring Login
155	17	FT:Crawl Started
156	17	FT:Crawl Stopped
157	17	FT:Crawl Aborted
158	8	Audit Broker Conversation
159	8	Audit Broker Login
160	16	Broker:Message Undeliverable
161	16	Broker:Corrupted Message
162	3	User Error Message
163	16	Broker:Activation
164	5	Object:Altered
165	6	Performance statistics
166	13	SQL:StmtRecompile
167	2	Database Mirroring State Change
168	6	Showplan XML For Query Compile
169	6	Showplan All For Query Compile
170	8	Audit Server Scope GDR Event
171	8	Audit Server Object GDR Event
172	8	Audit Database Object GDR Event
173	8	Audit Server Operation Event
175	8	Audit Server Alter Trace Event
176	8	Audit Server Object Management Event
177	8	Audit Server Principal Management Event
178	8	Audit Database Operation Event
180	8	Audit Database Object Access Event
181	12	TM: Begin Tran starting
182	12	TM: Begin Tran completed
183	12	TM: Promote Tran starting
184	12	TM: Promote Tran completed
185	12	TM: Commit Tran starting
186	12	TM: Commit Tran completed
187	12	TM: Rollback Tran starting
188	12	TM: Rollback Tran completed
189	4	Lock:Timeout (timeout > 0)
190	19	Progress Report: Online Index Operation
191	12	TM: Save Tran starting
192	12	TM: Save Tran completed
193	3	Background Job Error
194	15	OLEDB Provider Information
195	9	Mount Tape
196	20	Assembly Load
198	13	XQuery Static Type
199	21	QN: Subscription
200	21	QN: Parameter table
201	21	QN: Template
202	21	QN: Dynamics
212	3	Bitmap Warning
213	3	Database Suspect Data Page
214	3	CPU threshold exceeded
215	10	PreConnect:Starting
216	10	PreConnect:Completed
217	6	Plan Guide Successful
218	6	Plan Guide Unsuccessful
235	8	Audit Fulltext

