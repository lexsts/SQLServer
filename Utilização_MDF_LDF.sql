DECLARE  @rowcnt INT
DECLARE  @iterator INT
DECLARE  @dbname VARCHAR(200)
DECLARE  @exec_sql VARCHAR(500)
SET @rowcnt = 0
SET @iterator = 1
CREATE TABLE #db_file_info (
  [Database_Name]    SYSNAME    NOT NULL,
  [File_ID]          SMALLINT    NOT NULL,
  [File_Type]        VARCHAR(10)    NOT NULL,
  [File_Name]        SYSNAME    NOT NULL,
  [File_Path]        VARCHAR(500)    NOT NULL,
  [File_Size_in_MB]  INT    NOT NULL,
  [Space_Used_in_MB] INT    NOT NULL,
  [Space_Left_in_MB] INT    NOT NULL)
CREATE TABLE #db (
  dbid INT,
  name VARCHAR(200))
INSERT INTO #db
SELECT dbid,
       name
FROM   MASTER.dbo.sysdatabases
WHERE NAME NOT IN (SELECT NAME FROM SYS.DATABASES A WHERE STATE<>0)
SELECT @rowcnt=MAX(A.DATABASE_ID)
  FROM SYS.DATABASES A
  WHERE STATE=0
WHILE @iterator <= @rowcnt
  BEGIN
    SELECT @dbname = name
    FROM   #db
    WHERE  dbid = @iterator
    
    SET @exec_sql = ' USE "' + @dbname + '"; Insert into #DB_FILE_INFO
Select db_name(),fileid,case when groupid = 0 then ''log file'' else ''data file'' end,
name,filename, 

[file_size] = 
convert(int,round((sysfiles.size*1.000)/128.000,0)),
[space_used] =
convert(int,round(fileproperty(sysfiles.name,''SpaceUsed'')/128.000,0)),
[space_left] =
convert(int,round((sysfiles.size-fileproperty(sysfiles.name,''SpaceUsed''))/128.000,0))
from
dbo.sysfiles;
'
    
    EXEC( @exec_sql)
    
    SET @iterator = @iterator + 1
  END

SELECT DISTINCT A.*
FROM   #db_file_info A



DROP TABLE #db
DROP TABLE #db_file_info
