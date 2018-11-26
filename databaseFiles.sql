DECLARE @DBInfo TABLE  
( ServerName VARCHAR(100),  
DatabaseName VARCHAR(100),  
FileSizeMB INT,  
FileMaxSizeMB INT,
LogicalFileName sysname,  
PhysicalFileName NVARCHAR(520),  
Status sysname,  
Updateability sysname,  
RecoveryMode sysname,  
FreeSpaceMB INT,  
FreeSpacePct VARCHAR(7),  
FreeSpacePages INT,  
PollDate datetime)  

DECLARE @command VARCHAR(5000)  

SELECT @command = 'Use [' + '?' + '] SELECT  
@@servername as ServerName,  
' + '''' + '?' + '''' + ' AS DatabaseName,  
CAST(sysfiles.size/128.0 AS int) AS FileSize, 
CAST(sysfiles.maxsize/128.0 AS int) AS FileMaxSize, 
sysfiles.name AS LogicalFileName, 
sysfiles.filename AS PhysicalFileName,  
CONVERT(sysname,DatabasePropertyEx(''?'',''Status'')) AS Status,  
CONVERT(sysname,DatabasePropertyEx(''?'',''Updateability'')) AS Updateability,  
CONVERT(sysname,DatabasePropertyEx(''?'',''Recovery'')) AS RecoveryMode,  
CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name, ' + '''' +  
       'SpaceUsed' + '''' + ' ) AS int)/128.0 AS int) AS FreeSpaceMB,  
CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,  
' + '''' + 'SpaceUsed' + '''' + ' ) AS int)/128.0)/(sysfiles.size/128.0))  
AS decimal(4,2))) AS varchar(8)) + ' + '''' + '%' + '''' + ' AS FreeSpacePct,  
GETDATE() as PollDate FROM dbo.sysfiles'  
INSERT INTO @DBInfo  
   (ServerName,  
   DatabaseName,  
   FileSizeMB,  
   FileMaxSizeMB,  
   LogicalFileName,  
   PhysicalFileName,  
   Status,  
   Updateability,  
   RecoveryMode,  
   FreeSpaceMB,  
   FreeSpacePct,  
   PollDate)  
EXEC sp_MSForEachDB @command  

SELECT  
   PhysicalFileName,
   LogicalFileName,  
   DatabaseName,
   Status,  
   FileSizeMB,  
   CASE WHEN CAST(FileMaxSizeMB AS VARCHAR)='0' THEN 'UNLIMITED' WHEN CAST(FileMaxSizeMB AS VARCHAR)<>'0' THEN CAST(FileMaxSizeMB AS VARCHAR) END AS FileMaxSizeMB,
   CAST(CAST(((FileSizeMB*100)/CASE WHEN FileMaxSizeMB=0 THEN 999999 WHEN FileMaxSizeMB>0 THEN FileMaxSizeMB END) AS decimal(9,2)) AS VARCHAR) + '%' AS PercentageUsed,  
   Updateability,  
   RecoveryMode,  
   PollDate  
FROM @DBInfo  
ORDER BY  
   ServerName,  
   DatabaseName 
