select name,loginame, count(1)  from master..sysprocesses a, master..sysdatabases b
where a.dbid = b.dbid 
group by name,loginame
having count(1)  > 100


/*

select 'KILL ' + CAST(SPID AS VARCHAR) from master..sysprocesses a, master..sysdatabases b
where a.dbid = b.dbid 
AND B.NAME='SS_TRADE'
AND A.STATUS='SLEEPING'

*/