--A problem during startup process can cause this issue

ALTER DATABASE tpcc SET OFFLINE WITH ROLLBACK IMMEDIATE
go
ALTER DATABASE tpcc SET ONLINE WITH ROLLBACK IMMEDIATE
go
