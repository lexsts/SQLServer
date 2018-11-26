set nocount on;
DECLARE @tmp_log table
(spid varchar(200),
statuslogin varchar(200),
login_name varchar(200),
hostname varchar(200),
blkby varchar(200),
dbname varchar(200),
command varchar(200),
cputime varchar(200),
diskIO varchar(200),
lastbatch varchar(200),
programname  varchar(250),
SPIDS  varchar(200),
REQUESTID  varchar(200)
);


insert into @tmp_log
exec sp_who2;


SELECT DISTINCT LOGIN_NAME FROM @tmp_log WHERE DBNAME='SYSIN';